class CreateAdminInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_invitations do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.integer :role, null: false, default: 1 # admin by default
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :admin_invitations, :email
    add_index :admin_invitations, :token, unique: true
  end
end


