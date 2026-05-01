# Rent

A Rails app for landlords / property managers.

**Runs on [Once](https://once.com).** Rent is built to be installed and run on your own server — one customer, one box, no SaaS middleman. Your data lives on hardware you control. Deployment is a single `once install` against a fresh DigitalOcean droplet (or any Linux server you can SSH into).

One deployment per customer. No multi-tenancy, no shared infrastructure, no telemetry phoning home.

This README captures the decisions that shape the codebase. If you're about to write code that contradicts something here, change the README first (or argue with it).

---

## Stack

- **Rails 8** — latest stable. Pin in `Gemfile` and `.ruby-version` (currently Ruby 3.4.9 / Rails 8.1).
- **SQLite** — development *and* production. Single file per deployment. Backups = copy the file (or use Once's auto-backup).
- **Hotwire (Turbo + Stimulus)** — server-rendered HTML, Turbo Streams for interactivity. Avoid SPA patterns.
- **Importmap** — no Node, no bundler. If a feature needs npm, push back before adding it.
- **Oat.ink** — CSS framework. Self-hosted (`app/assets/stylesheets/oat.css`). Provides the `[data-sidebar-layout]` chrome.
- **Rails Event Store (RES)** — events are first-class. See *Architecture* below.
- **Twilio** — SMS for login codes. Configured via env vars (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_NUMBER`), not credentials.

## Testing

- **System tests only.** Capybara + rack_test driver. Tests drive the app the way a user does.
- No model, controller, request, or integration unit tests by policy. If a behavior matters, a system test asserts it. If it doesn't matter, don't test it.
- Twilio is replaced with `SmsClient::TestBackend` in the test environment. Tests assert on captured messages.
- Every code change ships with a system test that pins the behavior. The test is the spec.

## Tenancy

**None.** Rent is single-tenant per deployment. Each customer gets their own server, their own SQLite file, their own domain. There is no `tenant_id`, no domain-routing middleware, no shared infrastructure between customers. Onboarding a new customer means provisioning a new droplet and pointing DNS.

If you ever feel the urge to add multi-tenancy, stop and re-read this section.

---

## Architecture: Commands, Queries, Events, Reactors

Rent is event-driven. Controllers are thin wrappers — they call exactly one **command** (for writes) or one or more **queries** (for reads). Commands publish **events**. **Reactors** subscribe to events and do side effects (SMS, etc.). State is derived from the event log — no `users`, `properties`, or `applications` tables.

### The rules

1. **Controllers are thin.** Write actions call exactly **one command** plus any queries needed to render or redirect (e.g. fetching the just-issued token to set a cookie). Read actions call queries only — no commands. No business logic, no ActiveRecord, no inline event-store reads. If a controller needs data, it goes through a query object.
2. **Commands are pure event publishers.** They validate inputs, then publish exactly one event. Commands may **read** events for validation purposes, but they never **write** to the database — all writes happen in reactors. **Commands return `nil`** — there's no useful return value.
3. **Queries return a `Result`.** Every query defines `Result = Data.define(...)` and returns a `Result` instance — never an AR record, never a raw hash, never `nil`. The `Result` shape is the read-model contract; views and controllers depend on it.
4. **Result objects hold IDs only, never denormalized names.** A `LeaseView` carries `property_id` and `applicant_id` — *not* `property_name` and `applicant_name`. Views resolve names at render time via helpers (`property_link`, `applicant_link`, `applicant_name`). Internal-to-query lookups (e.g. for sorting) are fine, but they don't leak through `Result`.
5. **Reactors do the work.** Side effects (SMS, future webhooks) live in reactors. Reactors are subscribed in `config/initializers/event_store.rb`. Reactors that publish further events are allowed (e.g. `BootstrapFirstAdmin`).
6. **One event per user action.** The event records intent. Reactor failures are operational concerns (logs, monitoring) — they don't get their own events.
7. **Commands and queries take primitives only.** Pass `user_id:` not `user:`, `mobile:` not `User`. No ActiveRecord objects, no domain objects — just strings, integers, hashes of primitives. Forces the boundary to be explicit and keeps everything serializable.

### Errors

Commands raise `CommandError` (or a subclass) on validation failure. `ApplicationController` has a single `rescue_from CommandError` that redirects back with a flash. Subclasses inherit so you can match on specifics.

```ruby
class CommandError < StandardError; end
class InvalidMobile < CommandError; end
```

### Append-only event store

`event_store_events` has `BEFORE UPDATE` and `BEFORE DELETE` SQLite triggers that `RAISE(ABORT)`. Past events cannot be mutated or deleted from any process — buggy reactor, console, ad-hoc script. Triggers do not fire on `ROLLBACK`, so transactional test cleanup still works.

If you genuinely need to expunge an event (GDPR/legal): drop the triggers, do the work, recreate them — and treat that as a privileged operation.

### Streams

We use streams as the index into the log. Common stream names:

- `Mobile$<number>` — everything for a phone number (login codes, verifications, logouts).
- `Token$<token>` — auth state for one session.
- `Property$<uuid>` — everything that happens to one property.
- `Properties` — the deployment-wide property log (every property event linked here).
- `Applications` — the deployment-wide applications log.
- `Leases` — the deployment-wide leases log.

### RES browser

Mounted at `/res` in all environments, gated by HTTP Basic auth. Set `RES_BASIC_PASSWORD` env var on the deployment to enable; if unset, every request is denied. Username is ignored.

### Testing events

Don't write isolated unit tests for commands, queries, events, or reactors. The system test that drives the user-visible behavior exercises the whole chain.

```ruby
event = Rails.configuration.event_store.read.of_type([LoginCodeRequested]).last
assert_equal "+15551234567", event.data[:mobile]
```

---

## Authorization (ACL)

A single `Authorization::POLICIES` hash is the source of truth for who can do what. Keys are either command class names (`"AddProperty"`) or `Controller#action` pairs (`"Properties#index"`). Roles are `:public`, `:authenticated`, or `:admin`.

```ruby
"AddProperty"        => :admin,
"SubmitApplication"  => :public,
"Properties#index"   => :admin,
"Applicants#apply"   => :public,
```

Both layers consult the same hash:

- **Commands** call `Authorization.check!(actor: actor, key: self.name)` as their first line.
- **Controllers** have a global `before_action :authorize_action!` that calls `Authorization.check!(actor: current_user.mobile, key: "#{controller_name.camelize}##{action_name}")`.

Adding a route or command without a policy entry raises a loud `RuntimeError("No ACL policy for ...")` — defaults are deny.

### First user becomes admin

`BootstrapFirstAdmin` is a reactor subscribed to `LoginCodeVerified`. On every successful login it checks for any `UserPromotedToAdmin` event; if none exists, it publishes one for that mobile. The very first person to log in is automatically the admin. Subsequent users have role `:authenticated` (no admin abilities).

There is no UI yet for promoting other users; do it from `bin/rails console` or by publishing `UserPromotedToAdmin` directly.

---

## Authentication

No passwords. Mobile + SMS code only.

1. User submits mobile. `RequestLoginCode` generates a 6-digit code with a 10-minute expiry, publishes `LoginCodeRequested` to `Mobile$<mobile>`.
2. `SendLoginCodeSms` reactor sends the code via Twilio. (No DB write.)
3. User submits code. `VerifyLoginCode` reads the latest unverified `LoginCodeRequested`, validates with constant-time compare and expiry check, generates a token, publishes `LoginCodeVerified` to `Mobile$<mobile>` and `Token$<token>`.
4. Server sets a signed cookie holding the token.
5. Every request: the `CurrentUser` query reads `Token$<token>`. If it contains a `LoginCodeVerified` and no `LoggedOut`, the request is authenticated.
6. Logout publishes `LoggedOut` to `Token$<token>` and clears the cookie.

Rate limit: 5 code requests per mobile per hour, by counting events on `Mobile$<mobile>`.

---

## Domain features

### Properties

CRUD over properties (admin only). Each property has:

- `name` — public marketing label, e.g. "Charming Beachfront Cottage". Shown to anonymous visitors and used as the H1 on the public show page.
- `address` — internal label, e.g. "22 Lisgar Street". Shown to admins in tables and as a small line on the public show page.
- `slug` — URL identifier, auto-derived from name on create, editable on edit. Disambiguates with `-2`/`-3` if a base slug is taken.
- `beds`, `baths`, `description`.
- `published` — boolean. Unpublished properties are invisible to non-authenticated visitors (404). Default `false` on creation.

Events: `PropertyAdded`, `PropertyUpdated`, `PropertyRemoved`, `PropertyPublished`, `PropertyUnpublished`. Removed properties are tombstoned by the latest event being `PropertyRemoved` — the projection returns `nil`.

The public URL is `https://<host>/properties/:slug`.

### Applicants / Applications

Two flows:

1. **Public apply** — on a published property's show page, a visitor clicks "Apply for this property" → fills name / mobile / summary → `SubmitApplication` publishes `ApplicationSubmitted` with the property's id.
2. **Admin adhoc** — admin clicks "Add applicant" → fills name / mobile / summary, optionally selects a property → `AddApplicant` publishes `ApplicationSubmitted` with optional property_id (`nil` if not tied to a listing).

Both paths use the same event. Admin views show "(adhoc)" when `property_id` is nil.

Admin sees all applicants at `/applicants`; click an applicant for the detail view.

### Leases

A lease ties an applicant to a property over a date range. Created from the applicant detail page → fills property + start_date + (optional) end_date → `CreateLease` publishes `LeaseCreated`.

Validation in `CreateLease`:
- Applicant must exist.
- Property must exist.
- Start date must parse.
- End date must parse and be after start date if provided.
- **No overlap** — the new lease's `[start, end]` interval must not overlap any existing lease on the same property. `nil` end is treated as `+∞`.

Open-ended leases (no end date) are explicitly supported.

---

## Walked-through example: `POST /login` (write)

```ruby
# config/routes.rb
post "/login", to: "logins#create"
```

```ruby
# app/controllers/logins_controller.rb
def create
  RequestLoginCode.call(mobile: params[:mobile], ip: request.remote_ip)
  redirect_to login_verify_path, notice: "Code sent."
end
```

```ruby
# app/commands/request_login_code.rb
class RequestLoginCode
  CODE_TTL = 10.minutes

  def self.call(mobile:, ip:, actor: nil)
    Authorization.check!(actor: actor, key: name)

    normalized = Mobile.normalize(mobile)
    raise InvalidMobile, "Invalid mobile number." unless normalized

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
end
```

```ruby
# app/reactors/send_login_code_sms.rb
class SendLoginCodeSms
  def self.call(event)
    SmsClient.deliver(to: event.data[:mobile], body: "Your Rent code: #{event.data[:code]}")
  end
end
```

```ruby
# config/initializers/event_store.rb
Rails.configuration.event_store.subscribe(
  ->(event) { SendLoginCodeSms.call(event) },
  to: [LoginCodeRequested]
)
```

The reactor doesn't write anything — it just sends the SMS. The code lives in the event itself.

## Walked-through example: `GET /properties/:slug` (read)

```ruby
# app/controllers/properties_controller.rb
def show
  @property = PropertyBySlug.call(slug: params[:slug]).property
  visible = @property && (@property.published || authenticated?)
  unless visible
    redirect_to(authenticated? ? properties_path : login_path, alert: "Property not found.") and return
  end
end
```

```ruby
# app/queries/property_by_slug.rb
class PropertyBySlug
  Result = Data.define(:property)

  def self.call(slug:)
    match = Properties.call.properties.find { |p| p.slug == slug }
    Result.new(property: match)
  end
end
```

`Properties.call` reads the `Properties` stream and folds the events for each property into a `PropertyView` (id, slug, name, address, beds, …). The view renders `@property.name`, optionally `@property.address` if `admin?`, and an Apply button if published.

---

## Adding a feature: the recipe

1. Write a system test that drives the feature end-to-end as a user would.
2. **For writes:**
   - Define any new events in `app/events/`.
   - Add a command in `app/commands/` that validates inputs and publishes the event. First line: `Authorization.check!(actor:, key: self.name)`.
   - Add an entry to `Authorization::POLICIES` for the command.
   - Add side effects as a reactor in `app/reactors/` (subscribed in the event store initializer).
3. **For reads:**
   - Add a query in `app/queries/` returning a `Result` of primitives + ids.
   - Add a helper if names need resolution at render time.
4. Wire controller actions. Add `Authorization::POLICIES` entries for each new `Controller#action`.
5. Get the system test green.
6. Update this README if a decision changed.

---

## JSON API

Every existing CRUD controller (Properties, Applicants, Leases, Transactions) responds to `.json` with the same actions backed by the same commands and queries. There's no separate `/api/v1/` namespace — request `Content-Type: application/json` (or append `.json`) on any URL.

**Auth.** Pass `Authorization: Bearer <token>` where the token is one minted at `/api_tokens` (admin-only UI). Cookie auth still works for browsers; bearer auth wins when both are present. Tokens carry the privileges of the admin who created them.

**Errors.**
- `401 Unauthorized` — no actor (no valid bearer / cookie session).
- `403 Forbidden` — actor present but role insufficient.
- `404 Not Found` — record doesn't exist.
- `422 Unprocessable Entity` — `CommandError` (validation, business-rule violation).

**Examples.**

```bash
# List properties
curl -H "Authorization: Bearer $TOKEN" https://rent.stcroixproperties.ca/properties.json

# Create a property
curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"Beachfront","address":"22 Lisgar","beds":2,"baths":1,"description":""}' \
     https://rent.stcroixproperties.ca/properties.json

# Show one
curl -H "Authorization: Bearer $TOKEN" https://rent.stcroixproperties.ca/properties/beachfront.json

# Publish / unpublish / duplicate (POST, no body needed)
curl -X POST -H "Authorization: Bearer $TOKEN" https://rent.stcroixproperties.ca/properties/beachfront/publish.json
```

Response shapes are `Result.to_h` from the corresponding query — primitives + IDs only, never denormalized names. Clients resolve names by calling the relevant show endpoint or maintaining a local cache.

API tests live in `test/system/api/` (one file per resource).

---

## Local development

```
bin/setup
bin/rails server
bin/rails test:system
```

`bin/rails console` to poke the event store:

```ruby
es = Rails.configuration.event_store
es.read.to_a                                  # all events
es.read.stream("Properties").to_a             # one stream
es.read.of_type([PropertyAdded]).to_a         # by type
```

Or browse at `http://localhost:3000/res`.

---

## Production

- Docker image built by GitHub Actions on push to `main`, pushed to `ghcr.io/dallasread/rent:main`.
- Each customer runs on a DigitalOcean droplet, deployed via the **Once CLI**.
- Configure secrets per-droplet via `once update <host> --env KEY=VALUE`:
  - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_NUMBER` — for SMS login.
  - `RES_BASIC_PASSWORD` — gates the `/res` event browser.
- `SECRET_KEY_BASE` is provided by Once.
- SQLite database is mounted at `/rails/storage` (Once-managed, included in backups).

To pull a new image after a code change:

```
once update <host> --image ghcr.io/dallasread/rent:main
```

(env vars persist across updates).
