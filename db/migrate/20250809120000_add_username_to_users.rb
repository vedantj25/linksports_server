class AddUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string

    # Unique case-insensitive index for username
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE UNIQUE INDEX index_users_on_lower_username ON users (LOWER(username));
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP INDEX IF EXISTS index_users_on_lower_username;
        SQL
      end
    end
  end
end
