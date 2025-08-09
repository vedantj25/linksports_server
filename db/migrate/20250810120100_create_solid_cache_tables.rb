class CreateSolidCacheTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_cache_entries, id: :string, limit: 512 do |t|
      t.binary :value
      t.datetime :expires_at, precision: 6
      t.datetime :created_at, null: false, precision: 6
    end
    add_index :solid_cache_entries, :expires_at

    create_table :solid_cache_versions do |t|
      t.string :key, null: false, limit: 512
      t.string :version, null: false
      t.datetime :created_at, null: false, precision: 6
    end
    add_index :solid_cache_versions, [ :key, :version ], unique: true
  end
end
