class EnforceSingleYearInTournaments < ActiveRecord::Migration[8.0]
  # Lightweight AR model for migration use only
  class MigUserSportTournament < ActiveRecord::Base
    self.table_name = "user_sport_tournaments"
  end

  def up
    add_column :user_sport_tournaments, :year, :integer

    say_with_time "Backfilling tournament years" do
      MigUserSportTournament.reset_column_information
      MigUserSportTournament.find_each do |t|
        years_str = t.read_attribute(:years)
        years = years_str.to_s.scan(/\d{4}/).map(&:to_i).uniq

        next if years.empty?

        # Set the first year on the existing record
        t.update_columns(year: years.first)

        # For multiple years, create additional rows
        years.drop(1).each do |yr|
          MigUserSportTournament.create!(
            user_sport_id: t.user_sport_id,
            tournament_name: t.tournament_name,
            description: t.description,
            year: yr,
            created_at: t.created_at,
            updated_at: t.updated_at
          )
        end
      end
    end

    remove_column :user_sport_tournaments, :years, :string
    add_index :user_sport_tournaments, [ :user_sport_id, :tournament_name, :year ], unique: true, name: "idx_unique_tournament_per_year"
  end

  def down
    add_column :user_sport_tournaments, :years, :string

    say_with_time "Combining tournament years back to a single string" do
      # Group by user_sport_id + tournament_name, keep first row and merge others into years string
      groups = MigUserSportTournament.select(:user_sport_id, :tournament_name).distinct
      groups.find_each do |g|
        rows = MigUserSportTournament.where(user_sport_id: g.user_sport_id, tournament_name: g.tournament_name).order(:year)
        years = rows.map(&:year).compact
        first = rows.first
        if first
          first.update_columns(years: years.join(", "))
          rows.where.not(id: first.id).delete_all
        end
      end
    end

    remove_index :user_sport_tournaments, name: "idx_unique_tournament_per_year"
    remove_column :user_sport_tournaments, :year, :integer
  end
end
