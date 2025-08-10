class StructureAchievements < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :achievement_entries, :jsonb, default: []
    remove_column :profiles, :achievements, :text, array: true
  end
end
