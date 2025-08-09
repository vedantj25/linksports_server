class CreateSocialGraphAndPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :connections do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :addressee, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :connected_at
      t.timestamps
    end
    add_index :connections, [ :requester_id, :addressee_id ], unique: true

    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :sport, foreign_key: true
      t.text :content, null: false
      t.integer :visibility, null: false, default: 0
      t.integer :likes_count, null: false, default: 0
      t.integer :comments_count, null: false, default: 0
      t.timestamps
    end

    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.text :content, null: false
      t.timestamps
    end

    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.timestamps
    end
    add_index :likes, [ :user_id, :post_id ], unique: true
  end
end
