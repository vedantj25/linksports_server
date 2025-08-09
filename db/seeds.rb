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
