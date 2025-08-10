class ChangePositionAttributeBackToMultiSelect < ActiveRecord::Migration[8.0]
  def up
    say_with_time "Updating SportAttribute 'position' to multi_select" do
      execute("UPDATE sport_attributes SET field_type = 'multi_select' WHERE key = 'position'")
    end
  end

  def down
    say_with_time "Reverting SportAttribute 'position' to select" do
      execute("UPDATE sport_attributes SET field_type = 'select' WHERE key = 'position'")
    end
  end
end
