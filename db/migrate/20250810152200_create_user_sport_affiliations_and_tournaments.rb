class CreateUserSportAffiliationsAndTournaments < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sport_affiliations do |t|
      t.references :user_sport, null: false, foreign_key: true
      t.string :club_team_name, null: false
      t.string :league_competition
      t.integer :start_year
      t.integer :end_year
      t.text :description
      t.boolean :current, null: false, default: false
      t.timestamps
    end

    create_table :user_sport_tournaments do |t|
      t.references :user_sport, null: false, foreign_key: true
      t.string :tournament_name, null: false
      t.string :years
      t.text :description
      t.timestamps
    end
  end
end
