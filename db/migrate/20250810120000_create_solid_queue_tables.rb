class CreateSolidQueueTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_queue_queues do |t|
      t.string :name, null: false
      t.integer :limit
      t.timestamps precision: 6, null: false
    end
    add_index :solid_queue_queues, :name, unique: true

    create_table :solid_queue_jobs do |t|
      t.references :queue, null: false, foreign_key: { to_table: :solid_queue_queues }
      t.string :klass, null: false
      t.text :arguments
      t.integer :priority, default: 0
      t.datetime :scheduled_at, precision: 6
      t.datetime :finished_at, precision: 6
      t.string :status, null: false, default: "pending"
      t.timestamps precision: 6, null: false
    end
    add_index :solid_queue_jobs, [ :queue_id, :status ]

    create_table :solid_queue_workers do |t|
      t.string :name, null: false
      t.datetime :last_heartbeat_at, precision: 6
      t.timestamps precision: 6, null: false
    end

    create_table :solid_queue_recurring_tasks do |t|
      t.string :name, null: false
      t.string :task, null: false
      t.text :arguments
      t.string :schedule, null: false
      t.datetime :last_enqueued_at, precision: 6
      t.timestamps precision: 6, null: false
    end
    add_index :solid_queue_recurring_tasks, :name, unique: true
  end
end
