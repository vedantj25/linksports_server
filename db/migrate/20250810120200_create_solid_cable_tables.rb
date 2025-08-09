class CreateSolidCableTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_cable_messages do |t|
      t.string :stream, null: false
      t.text :data, null: false
      t.datetime :created_at, null: false, precision: 6
    end
    add_index :solid_cable_messages, :stream

    create_table :solid_cable_streams do |t|
      t.string :stream, null: false
      t.string :connection_identifier, null: false
      t.datetime :created_at, null: false, precision: 6
    end
    add_index :solid_cable_streams, [ :stream, :connection_identifier ], unique: true
  end
end
