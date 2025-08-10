class RestructureEducationAndTraining < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :academic_education_entries, :jsonb, default: []
    add_column :profiles, :training_camp_entries, :jsonb, default: []

    # Remove deprecated fields
    remove_column :profiles, :training_history, :json
    remove_column :profiles, :academic_education, :text, array: true
    remove_column :profiles, :training_camps, :text, array: true
  end
end
