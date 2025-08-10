class AddMediaFieldsToProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :highlight_videos, :text, array: true, default: []
    add_column :profiles, :media_links, :text, array: true, default: []
  end
end
