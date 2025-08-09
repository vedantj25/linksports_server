class EnforceUsernameAndContacts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :username, false

    # Remove obsolete phone verification fields from users
    remove_column :users, :phone_verification_code, :string
    remove_column :users, :phone_verification_sent_at, :datetime

    # Keep users.verified for now? We will stop using it and switch checks to user_contacts
    # If you want to drop it, uncomment below after app code updated
    # remove_column :users, :verified, :boolean

    # Remove profiles.slug
    remove_column :profiles, :slug, :string
  end
end
