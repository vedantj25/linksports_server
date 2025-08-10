class CreateSportAttributesAndMappings < ActiveRecord::Migration[8.0]
  def change
    create_table :sport_attributes do |t|
      t.string :key, null: false
      t.string :label, null: false
      t.string :field_type, null: false, default: "string" # string, select, multi_select
      t.text :options, array: true, default: []            # for select types
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :sport_attributes, :key, unique: true

    create_table :sport_attribute_mappings do |t|
      t.references :sport, null: false, foreign_key: true
      t.references :sport_attribute, null: false, foreign_key: true
      t.timestamps
    end
    add_index :sport_attribute_mappings, [ :sport_id, :sport_attribute_id ], unique: true, name: "index_sport_attr_mappings_on_sport_and_attribute"
  end
end
