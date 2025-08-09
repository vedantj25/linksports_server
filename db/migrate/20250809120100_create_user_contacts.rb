class CreateUserContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :user_contacts do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :contact_type, null: false, default: 0 # 0: email, 1: phone
      t.string :value, null: false
      t.boolean :verified, default: false, null: false
      t.string :verification_code
      t.datetime :verification_sent_at
      t.integer :verification_attempts, default: 0, null: false
      t.datetime :last_sent_at
      t.integer :daily_send_count, default: 0, null: false

      t.timestamps
    end

    add_index :user_contacts, [ :user_id, :contact_type ], name: "index_user_contacts_on_user_and_type"
    add_index :user_contacts, [ :contact_type, :value ], unique: true, name: "index_user_contacts_on_type_and_value_unique"
  end
end
