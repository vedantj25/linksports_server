class AddMonthsToUserSportAffiliations < ActiveRecord::Migration[8.0]
  def change
    add_column :user_sport_affiliations, :start_month, :integer
    add_column :user_sport_affiliations, :end_month, :integer
  end
end
