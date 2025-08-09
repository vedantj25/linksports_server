class AddSoftDeleteAndCommentsFlags < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :deleted_at, :datetime
    add_column :posts, :comments_enabled, :boolean, null: false, default: true
    add_index :posts, :deleted_at

    add_column :comments, :deleted_at, :datetime
    add_index :comments, :deleted_at
  end
end


