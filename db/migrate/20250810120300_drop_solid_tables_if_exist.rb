class DropSolidTablesIfExist < ActiveRecord::Migration[8.0]
  def up
    drop_table :solid_queue_jobs, if_exists: true
    drop_table :solid_queue_queues, if_exists: true
    drop_table :solid_queue_workers, if_exists: true
    drop_table :solid_queue_recurring_tasks, if_exists: true
    drop_table :solid_cache_entries, if_exists: true
    drop_table :solid_cache_versions, if_exists: true
    drop_table :solid_cable_messages, if_exists: true
    drop_table :solid_cable_streams, if_exists: true
  end

  def down
    # no-op
  end
end
