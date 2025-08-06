class CreateUserSports < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :sport, null: false, foreign_key: true
      t.string :position
      t.integer :skill_level
      t.integer :years_experience
      t.boolean :primary

      t.timestamps
    end
  end
end
