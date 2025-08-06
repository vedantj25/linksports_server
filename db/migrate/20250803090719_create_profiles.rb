class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type, null: false # STI discriminator

      # Common profile fields
      t.string :first_name, null: false
      t.string :last_name
      t.string :display_name
      t.text :bio
      t.date :date_of_birth
      t.integer :gender
      t.string :location_city
      t.string :location_state
      t.string :location_country, default: 'India'
      t.string :website_url
      t.string :instagram_url
      t.string :youtube_url
      t.json :privacy_settings, default: {}

      # Player specific fields
      t.integer :height_cm
      t.integer :weight_kg
      t.integer :preferred_foot
      t.integer :playing_status, default: 0
      t.integer :availability, default: 0
      t.text :achievements, array: true, default: []
      t.json :training_history, default: []

      # Coach specific fields
      t.integer :experience_years
      t.text :coaching_philosophy
      t.text :certifications, array: true, default: []
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.string :currency, default: 'INR'
      t.boolean :available_for_hire, default: true
      t.json :coaching_history, default: []

      # Club specific fields
      t.string :club_name
      t.integer :club_type
      t.integer :establishment_year
      t.text :facilities, array: true, default: []
      t.text :programs_offered, array: true, default: []
      t.string :contact_person
      t.string :contact_email
      t.string :contact_phone
      t.text :address

      t.timestamps
    end

    add_index :profiles, :type
    add_index :profiles, [ :location_city, :location_state ]
    add_index :profiles, :club_type
    add_index :profiles, :playing_status
    add_index :profiles, :availability
  end
end
