class AddAdminRolesAndAudit < ActiveRecord::Migration[8.0]
  def change
    # Roles on users
    add_column :users, :role, :integer, null: false, default: 0 # 0=user, 1=admin, 2=moderator (future)
    add_column :users, :banned, :boolean, null: false, default: false
    add_column :users, :banned_reason, :string
    add_column :users, :banned_at, :datetime
    add_column :users, :deleted_at, :datetime
    add_index :users, :role
    add_index :users, :deleted_at

    # Audit logs
    create_table :audit_logs do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.string :reason
      t.jsonb :changeset, default: {}
      t.inet :ip_address
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [:record_type, :record_id]
  end
end


