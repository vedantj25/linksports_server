class PlayerExtraFields < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :key_strengths, :text, array: true, default: []
    add_column :profiles, :fitness_tests, :text, array: true, default: []
    add_column :profiles, :academic_education, :text, array: true, default: []
    add_column :profiles, :training_camps, :text, array: true, default: []

    # Remove skill level entirely from user_sports per decision
    remove_column :user_sports, :skill_level, :integer
  end
end
