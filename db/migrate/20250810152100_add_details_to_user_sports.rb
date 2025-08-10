class AddDetailsToUserSports < ActiveRecord::Migration[8.0]
  def change
    add_column :user_sports, :details, :jsonb, default: {}
  end
end
