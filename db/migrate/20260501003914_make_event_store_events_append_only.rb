class MakeEventStoreEventsAppendOnly < ActiveRecord::Migration[8.1]
  # Enforces "events are facts; facts don't change" at the database layer.
  #
  # SQLite has no role-based revoke, so the closest equivalent to write-once is
  # BEFORE UPDATE / BEFORE DELETE triggers that RAISE(ABORT). Any process —
  # a buggy reactor, a misconfigured console — gets a hard error if it tries to
  # mutate or delete a past event.
  #
  # ROLLBACK does not fire these triggers, so transactional test cleanup (Rails
  # default) keeps working. If you ever switch to truncation-based cleanup,
  # drop and recreate these triggers around the truncation.
  def up
    execute <<~SQL
      CREATE TRIGGER event_store_events_no_update
      BEFORE UPDATE ON event_store_events
      BEGIN
        SELECT RAISE(ABORT, 'event_store_events is append-only');
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER event_store_events_no_delete
      BEFORE DELETE ON event_store_events
      BEGIN
        SELECT RAISE(ABORT, 'event_store_events is append-only');
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS event_store_events_no_update;"
    execute "DROP TRIGGER IF EXISTS event_store_events_no_delete;"
  end
end
