# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Sports
sports_data = [
  # Team Sports
  { name: "Football", category: "Team Sports" },
  { name: "Basketball", category: "Team Sports" },
  { name: "Cricket", category: "Team Sports" },
  { name: "Hockey", category: "Team Sports" },
  { name: "Volleyball", category: "Team Sports" },
  { name: "Kabaddi", category: "Team Sports" },
  { name: "Handball", category: "Team Sports" },

  # Individual Sports
  { name: "Tennis", category: "Individual Sports" },
  { name: "Badminton", category: "Individual Sports" },
  { name: "Swimming", category: "Individual Sports" },
  { name: "Athletics", category: "Individual Sports" },
  { name: "Boxing", category: "Individual Sports" },
  { name: "Wrestling", category: "Individual Sports" },
  { name: "Weightlifting", category: "Individual Sports" },
  { name: "Cycling", category: "Individual Sports" },
  { name: "Golf", category: "Individual Sports" },
  { name: "Table Tennis", category: "Individual Sports" },

  # Racket Sports
  { name: "Squash", category: "Racket Sports" },

  # Water Sports
  { name: "Water Polo", category: "Water Sports" },
  { name: "Diving", category: "Water Sports" },

  # Combat Sports
  { name: "Judo", category: "Combat Sports" },
  { name: "Karate", category: "Combat Sports" },
  { name: "Taekwondo", category: "Combat Sports" },

  # Other Sports
  { name: "Archery", category: "Other Sports" },
  { name: "Shooting", category: "Other Sports" },
  { name: "Chess", category: "Other Sports" }
]

sports_data.each do |sport_attrs|
  Sport.find_or_create_by!(name: sport_attrs[:name]) do |sport|
    sport.category = sport_attrs[:category]
    sport.active = true
  end
end

puts "Created #{Sport.count} sports"

############################################################
# Seed comprehensive SportAttributes and per-sport mappings #
############################################################

# 1) Define attribute catalog (global, unique by key)
ATTRIBUTE_DEFINITIONS = [
  # Generic
  { key: 'playing_style',        label: 'Playing Style / Specialization', field_type: 'string',       options: [] },
  { key: 'preferred_foot',       label: 'Preferred Foot',                 field_type: 'select',       options: %w[Left Right Both] },
  { key: 'dominant_hand',        label: 'Dominant Hand',                  field_type: 'select',       options: %w[Left Right Both] },

  # Football / Hockey
  { key: 'football_position',    label: 'Playing Positions',              field_type: 'multi_select', options: [ 'Forward', 'Midfielder', 'Defender', 'Goalkeeper' ] },
  { key: 'hockey_position',      label: 'Playing Positions',              field_type: 'multi_select', options: [ 'Forward', 'Midfielder', 'Defender', 'Goalkeeper' ] },

  # Basketball
  { key: 'basketball_position',  label: 'Playing Positions',              field_type: 'multi_select', options: [ 'Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center' ] },
  { key: 'shooting_hand',        label: 'Shooting Hand',                  field_type: 'select',       options: %w[Left Right Both] },

  # Volleyball
  { key: 'volleyball_position',  label: 'Playing Positions',              field_type: 'multi_select', options: [ 'Setter', 'Outside Hitter', 'Opposite', 'Middle Blocker', 'Libero' ] },

  # Kabaddi
  { key: 'kabaddi_role',         label: 'Role',                            field_type: 'select',       options: [ 'Raider', 'Defender', 'All-rounder' ] },

  # Handball
  { key: 'handball_position',    label: 'Playing Positions',              field_type: 'multi_select', options: [ 'Goalkeeper', 'Left Wing', 'Left Back', 'Center Back', 'Right Back', 'Right Wing', 'Pivot' ] },

  # Cricket
  { key: 'batting_style',        label: 'Batting Style',                  field_type: 'select',       options: [ 'Right-hand Bat', 'Left-hand Bat' ] },
  { key: 'bowling_style',        label: 'Bowling Style',                  field_type: 'select',       options: [ 'Right-arm Fast', 'Right-arm Medium', 'Right-arm Offbreak', 'Right-arm Legbreak', 'Left-arm Fast', 'Left-arm Medium', 'Left-arm Orthodox', 'Left-arm Chinaman' ] },
  { key: 'cricket_role',         label: 'Primary Role',                   field_type: 'select',       options: [ 'Batter', 'Bowler', 'All-rounder', 'Wicket-keeper' ] },

  # Racket Sports (Tennis, Badminton, Squash, Table Tennis)
  { key: 'racket_dominant_hand', label: 'Dominant Hand',                  field_type: 'select',       options: %w[Left Right Both] },
  { key: 'tt_grip_style',        label: 'Grip Style',                     field_type: 'select',       options: [ 'Shakehand', 'Penhold' ] },

  # Swimming
  { key: 'swim_strokes',         label: 'Strokes',                        field_type: 'multi_select', options: [ 'Freestyle', 'Breaststroke', 'Backstroke', 'Butterfly', 'Medley' ] },
  { key: 'swim_distances',       label: 'Preferred Distances',            field_type: 'multi_select', options: [ '50m', '100m', '200m', '400m', '800m', '1500m' ] },

  # Athletics
  { key: 'athletics_events',     label: 'Events',                         field_type: 'multi_select', options: [ '100m', '200m', '400m', '800m', '1500m', '5000m', '10000m', 'Marathon', '110m Hurdles', '400m Hurdles', 'High Jump', 'Long Jump', 'Triple Jump', 'Pole Vault', 'Shot Put', 'Discus Throw', 'Javelin Throw', 'Decathlon', 'Heptathlon' ] },

  # Combat Sports
  { key: 'boxing_stance',        label: 'Boxing Stance',                  field_type: 'select',       options: [ 'Orthodox', 'Southpaw' ] },
  { key: 'wrestling_style',      label: 'Wrestling Style',                field_type: 'select',       options: [ 'Freestyle', 'Greco-Roman' ] },
  { key: 'belt_rank',            label: 'Belt Rank',                      field_type: 'select',       options: [ 'White', 'Yellow', 'Orange', 'Green', 'Blue', 'Brown', 'Black' ] },
  { key: 'weight_class',         label: 'Weight Class',                   field_type: 'select',       options: [ '48kg', '52kg', '57kg', '63kg', '69kg', '75kg', '81kg', '91kg', '+91kg' ] },

  # Cycling
  { key: 'cycling_discipline',   label: 'Discipline',                     field_type: 'select',       options: [ 'Road', 'Track', 'Mountain Bike', 'BMX', 'Cyclocross', 'Time Trial' ] },

  # Golf
  { key: 'golf_handicap',        label: 'Handicap',                       field_type: 'string',       options: [] },

  # Water Polo
  { key: 'water_polo_position',  label: 'Playing Positions',              field_type: 'multi_select', options: [ 'Goalkeeper', 'Center', 'Driver', 'Wing', 'Point' ] },

  # Diving
  { key: 'diving_apparatus',     label: 'Apparatus',                      field_type: 'select',       options: [ '1m Springboard', '3m Springboard', '10m Platform' ] },

  # Archery
  { key: 'archery_bow_type',     label: 'Bow Type',                       field_type: 'select',       options: [ 'Recurve', 'Compound', 'Barebow' ] },

  # Shooting
  { key: 'shooting_discipline',  label: 'Discipline',                     field_type: 'select',       options: [ '10m Air Rifle', '50m Rifle', '10m Air Pistol', '25m Pistol', '50m Pistol', 'Shotgun - Trap', 'Shotgun - Skeet' ] },
  { key: 'dominant_eye',         label: 'Dominant Eye',                   field_type: 'select',       options: %w[Left Right] },

  # Chess
  { key: 'fide_title',           label: 'FIDE Title',                     field_type: 'select',       options: [ 'GM', 'IM', 'FM', 'CM', 'WGM', 'WIM', 'WFM', 'WCM' ] }
].freeze

ATTRIBUTE_DEFINITIONS.each do |attrs|
  sa = SportAttribute.find_or_initialize_by(key: attrs[:key])
  sa.label = attrs[:label]
  sa.field_type = attrs[:field_type]
  sa.options = attrs[:options]
  sa.active = true if sa.active.nil?
  sa.save!
end

# 2) Map attributes to each sport precisely (add missing, remove extraneous)
SPORT_ATTRIBUTE_KEYS_BY_SPORT_NAME = {
  # Team Sports
  'Football'     => %w[football_position preferred_foot playing_style],
  'Basketball'   => %w[basketball_position shooting_hand playing_style],
  'Cricket'      => %w[cricket_role batting_style bowling_style playing_style],
  'Hockey'       => %w[hockey_position playing_style],
  'Volleyball'   => %w[volleyball_position playing_style],
  'Kabaddi'      => %w[kabaddi_role playing_style],
  'Handball'     => %w[handball_position dominant_hand playing_style],

  # Individual Sports
  'Tennis'       => %w[racket_dominant_hand playing_style],
  'Badminton'    => %w[racket_dominant_hand playing_style],
  'Swimming'     => %w[swim_strokes swim_distances],
  'Athletics'    => %w[athletics_events],
  'Boxing'       => %w[boxing_stance weight_class],
  'Wrestling'    => %w[wrestling_style weight_class],
  'Weightlifting'=> %w[weight_class],
  'Cycling'      => %w[cycling_discipline playing_style],
  'Golf'         => %w[golf_handicap dominant_hand],
  'Table Tennis' => %w[racket_dominant_hand tt_grip_style playing_style],

  # Racket Sports
  'Squash'       => %w[racket_dominant_hand playing_style],

  # Water Sports
  'Water Polo'   => %w[water_polo_position playing_style],
  'Diving'       => %w[diving_apparatus],

  # Combat Sports
  'Judo'         => %w[belt_rank weight_class],
  'Karate'       => %w[belt_rank weight_class],
  'Taekwondo'    => %w[belt_rank weight_class],

  # Other Sports
  'Archery'      => %w[archery_bow_type dominant_hand],
  'Shooting'     => %w[shooting_discipline dominant_eye],
  'Chess'        => %w[fide_title playing_style]
}.freeze

Sport.find_each do |sport|
  desired_keys = SPORT_ATTRIBUTE_KEYS_BY_SPORT_NAME[sport.name] || []
  desired_attribute_ids = SportAttribute.where(key: desired_keys).pluck(:id).to_set

  existing_mappings = sport.sport_attribute_mappings.includes(:sport_attribute)
  existing_attribute_ids = existing_mappings.map(&:sport_attribute_id).to_set

  # Remove extraneous mappings
  (existing_attribute_ids - desired_attribute_ids).each do |attr_id|
    existing_mappings.find { |m| m.sport_attribute_id == attr_id }&.destroy!
  end

  # Add missing mappings
  (desired_attribute_ids - existing_attribute_ids).each do |attr_id|
    SportAttributeMapping.create!(sport: sport, sport_attribute_id: attr_id)
  end
end

puts "Seeded #{SportAttribute.count} sport attributes and mapped them to #{Sport.count} sports"

# Seed initial admin if none
if User.where(role: :admin).count.zero?
  admin_email = ENV.fetch("INITIAL_ADMIN_EMAIL", "admin@example.com")
  admin_password = ENV.fetch("INITIAL_ADMIN_PASSWORD", "password123")
  admin = User.find_or_initialize_by(email: admin_email)
  if admin.new_record?
    admin.assign_attributes(
      password: admin_password,
      password_confirmation: admin_password,
      phone: "+911234567890",
      user_type: :club,
      first_name: "Admin",
      last_name: "User",
      username: "admin_user",
      verified: true,
      role: :admin
    )
    admin.save!
  else
    admin.update!(role: :admin)
  end
  # Ensure email contact exists and is verified for seeded admin
  email_contact = admin.email_contact || admin.user_contacts.create!(contact_type: :email, value: admin.email)
  email_contact.update!(verified: true)
  puts "Seeded initial admin: #{admin.email}"
end
