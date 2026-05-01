# Rent

A Rails app for landlords / property managers.

**Runs on [Once](https://once.com).** Rent is built to be installed and run on your own server — one customer, one box, no SaaS middleman. Your data lives on hardware you control. Deployment is a single `once install` against a fresh DigitalOcean droplet (or any Linux server you can SSH into).

One deployment per customer. No multi-tenancy, no shared infrastructure, no telemetry phoning home.

This README captures the decisions that shape the codebase. If you're about to write code that contradicts something here, change the README first (or argue with it).

---

## Stack

- **Rails** — latest stable. Pin in `Gemfile` and `.ruby-version`.
- **Ruby** — latest stable supported by that Rails.
- **SQLite** — development *and* production. Single file per deployment. Backups = copy the file.
- **Hotwire (Turbo + Stimulus)** — default Rails 8 frontend. Server-rendered, Turbo Streams for interactivity. Avoid SPA patterns.
- **Importmap** — no Node, no bundler. If a feature needs npm, push back before adding it.
- **Oat.ink** — CSS framework. Classless-leaning; HTML stays semantic.
- **Rails Event Store (RES)** — events are first-class. See *Events* below.
- **Twilio** — SMS for login codes. No other notification channel for now.

## Testing

- **System tests only.** Capybara, headless browser. Tests drive the app the way a user does.
- No model, controller, request, or integration unit tests by policy. If a behavior matters, a system test asserts it. If it doesn't matter, don't test it.
- Twilio is replaced with an in-memory test client in the test environment. Tests assert on captured messages.
- Every code change ships with a system test that pins the behavior. The test is the spec.

## Authentication

No passwords. No `users` table. Authentication state is derived entirely from events.

1. User submits mobile number. The command generates a 6-digit code and an `expires_at` timestamp, then publishes `LoginCodeRequested(mobile, code, expires_at, ip, requested_at)` to the `Mobile$<mobile>` stream.
2. The `SendLoginCodeSms` reactor sends the SMS. (No DB write.)
3. User submits code. The `VerifyLoginCode` command reads the latest `LoginCodeRequested` event for this mobile, validates (constant-time compare; not expired; no later `LoginCodeVerified` event yet for that request), generates a token, and publishes `LoginCodeVerified(mobile, request_event_id, token, verified_at)` to both `Mobile$<mobile>` and `Token$<token>` streams.
4. Server sets a signed cookie holding the token.
5. Every request looks up the `Token$<token>` stream. If it contains a `LoginCodeVerified` and no `LoggedOut`, the request is authenticated. The user's identity is the `mobile` from the event.
6. Logout publishes `LoggedOut(token, logged_out_at)` to the `Token$<token>` stream and clears the cookie.

Rate limit: max 5 code requests per mobile per hour. Implemented by counting recent `LoginCodeRequested` events on the `Mobile$<mobile>` stream.

### Why no users table?

Pure event-sourcing — events are the only source of truth. State (who is logged in, who is registered, etc.) is derived by reading the appropriate stream. This is the spine of the app; introducing read tables for things like "list of users" should be a deliberate, README-changing decision.

### Performance footnote

Stream-keyed lookups (`Token$<token>`, `Mobile$<mobile>`) are indexed and stay fast. Cross-cutting lookups ("how many users have ever logged in?") require scanning events and will slow down with volume. When that becomes a real problem (not before), introduce a projection table maintained by a reactor — *only* the projection it needs, not a general-purpose `users` table.

## Tenancy

**None.** Rent is single-tenant per deployment. Each customer gets their own server, their own SQLite file, their own domain. There is no `tenant_id`, no domain-routing middleware, no shared infrastructure between customers. Onboarding a new customer means provisioning a new droplet and pointing DNS.

If you ever feel the urge to add multi-tenancy, stop and re-read this section.

## Deployment

- Docker image built by GitHub Actions, pushed to GitHub Container Registry.
- Each customer runs on a DigitalOcean droplet, deployed via the Basecamp Once CLI.
- Secrets via Rails encrypted credentials (Twilio, etc.). The decryption key is the only thing the droplet needs that isn't in the image.

---

## Architecture: Commands, Queries, Events, Reactors

Rent is event-driven. Controllers are thin wrappers — they call exactly one **command** (for writes) or one **query** (for reads). Commands publish **events**. **Reactors** subscribe to events and do the actual work (DB writes, SMS, etc.). Queries return data.

### The rules

1. **Controllers are thin.** Write actions call exactly **one command** plus any queries they need to render or redirect (e.g. fetching the just-issued token to set a cookie). Read actions call queries only — no commands. No business logic, no ActiveRecord, no inline event-store reads. If a controller needs data, it goes through a query object.
2. **Commands are pure event publishers.** They validate inputs, then publish exactly one event. Commands may **read** from the database for validation purposes (e.g., "does this user exist?", "is this submitted code valid?"), but they never **write** — all writes happen in reactors. **Commands return nothing** (`nil`) — there's no useful return value, and callers must not rely on one.
3. **Queries return a `Result`.** Every query defines `Result = Data.define(...)` and returns a `Result` instance — never an AR record, never a raw hash, never `nil`. The `Result` shape is the read-model contract; views and controllers depend on it, not on AR internals. Queries never publish events and never write.
4. **Reactors do the work.** All database writes and side effects live in reactors. Reactors are plain Ruby objects subscribed to events in `config/initializers/event_store.rb`.
5. **One event per user action.** The event records intent. Reactor failures are operational concerns (logs, monitoring) — they don't get their own events.
6. **Commands and queries take primitives only.** Pass `user_id:` not `user:`, `mobile:` not `User`. No ActiveRecord objects, no domain objects — just strings, integers, hashes of primitives. This keeps them serializable, easy to call from anywhere (controller, console, background job, future API), and forces the boundary to be explicit.

### Errors

Commands raise `CommandError` (or a subclass) when validation fails. `ApplicationController` has a single `rescue_from CommandError` that re-renders the form with a flash error. Specific failures inherit from `CommandError` so we can match on subclasses if we ever need to.

```ruby
class CommandError < StandardError; end
class InvalidMobile < CommandError; end
```

### Walked-through example: `POST /login` (write)

```ruby
# config/routes.rb
get  "/login", to: "logins#new"
post "/login", to: "logins#create"
```

```ruby
# app/controllers/logins_controller.rb
class LoginsController < ApplicationController
  def new; end

  def create
    RequestLoginCode.call(mobile: params[:mobile], ip: request.remote_ip)
    redirect_to login_verify_path, notice: "Code sent."
  end
end
```

```ruby
# app/commands/request_login_code.rb
class RequestLoginCode
  CODE_TTL = 10.minutes
  RATE_LIMIT = 5
  RATE_WINDOW = 1.hour

  def self.call(mobile:, ip:)
    normalized = Mobile.normalize(mobile)
    raise InvalidMobile, "Invalid mobile number." unless normalized
    raise RateLimited, "Too many attempts." if rate_limited?(normalized)

    Rails.configuration.event_store.publish(
      LoginCodeRequested.new(data: {
        mobile: normalized,
        code: format("%06d", SecureRandom.random_number(1_000_000)),
        expires_at: Time.current + CODE_TTL,
        ip: ip,
        requested_at: Time.current
      }),
      stream_name: "Mobile$#{normalized}"
    )
    nil
  end

  def self.rate_limited?(mobile)
    Rails.configuration.event_store.read
      .stream("Mobile$#{mobile}")
      .of_type([LoginCodeRequested])
      .last(RATE_LIMIT)
      .count { |e| e.metadata[:timestamp] >= Time.current - RATE_WINDOW } >= RATE_LIMIT
  end
end
```

```ruby
# app/events/login_code_requested.rb
class LoginCodeRequested < RailsEventStore::Event
  # data: { mobile:, code:, expires_at:, ip:, requested_at: }
end
```

```ruby
# app/reactors/send_login_code_sms.rb
class SendLoginCodeSms
  def self.call(event)
    SmsClient.deliver(
      to: event.data[:mobile],
      body: "Your Rent code: #{event.data[:code]}"
    )
  end
end
```

```ruby
# config/initializers/event_store.rb
Rails.configuration.event_store.subscribe(SendLoginCodeSms, to: [LoginCodeRequested])
```

The reactor doesn't write anything — it just sends the SMS. The code lives in the event itself.

### Walked-through example: `GET /dashboard` (read)

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def show
    @dashboard = UserDashboard.call(mobile: current_mobile)
  end
end
```

```ruby
# app/queries/user_dashboard.rb
class UserDashboard
  Result = Data.define(:mobile)

  def self.call(mobile:)
    Result.new(mobile: mobile)
  end
end
```

The view gets `@dashboard.mobile`. If the dashboard later needs login history, recent activity, etc., they're added to `Result` and the query reads them from event streams. The query owns the read-model shape; the view never sees raw events.

### Streams

Per-aggregate streams: `Mobile$<number>`, `User$<id>`. The global stream (`all`) is implicit.

### Append-only event store

The `event_store_events` table has `BEFORE UPDATE` and `BEFORE DELETE` triggers that `RAISE(ABORT)`. Past events cannot be mutated or deleted from any process — buggy reactor, console, ad-hoc script. The triggers do not fire on `ROLLBACK`, so transactional test cleanup still works.

If you genuinely need to expunge an event (legal/GDPR), drop the triggers, do the work, recreate the triggers — and treat that procedure as a privileged operation.

### Testing events

Don't write isolated unit tests for commands, queries, events, or reactors. The system test that drives the user-visible behavior exercises the whole chain. If you need to assert an event was published, do it inside the system test:

```ruby
event = Rails.configuration.event_store.read.of_type([LoginCodeRequested]).last
assert_equal "+15551234567", event.data[:mobile]
```

### Initial events

- `LoginCodeRequested` — `{ mobile, ip, requested_at }`
- `LoginCodeVerified` — `{ user_id, verified_at }`
- `LoggedOut` — `{ user_id, logged_out_at }`

---

## Adding a feature: the recipe

1. Write a system test that drives the feature end-to-end as a user would.
2. **For writes:**
   - Define any new events in `app/events/`.
   - Add a command in `app/commands/` that validates inputs and publishes the event.
   - Wire a controller action that calls the command.
   - Add a reactor in `app/reactors/` (subscribed in the event store initializer) to do the work.
3. **For reads:**
   - Add a query in `app/queries/` that returns the data the view needs.
   - Wire a controller action that calls the query and renders.
4. Get the system test green.
5. Update this README if a decision changed.

---

## API (deferred)

A JSON API will eventually live at `api.rent.<customer-domain>` and use bearer tokens for authentication. Not built yet — flagged here so we don't paint ourselves into a corner. The command/query/event/reactor pattern means adding API controllers later is mechanical: same commands and queries, different controllers that respond JSON.

---

## Local development

```
bin/setup
bin/rails server
```

System tests:

```
bin/rails test:system
```

## Production

Deployed via Once CLI to a DigitalOcean droplet per customer. See `docs/deploy.md` (TODO).
