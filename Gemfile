source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Authentication & Authorization
gem "devise"
gem "devise-jwt"
gem "pundit"

# Background Jobs
gem "sidekiq"

# API & Serialization
gem "jsonapi-serializer"
gem "rack-cors"
gem "rack-attack"

# Pagination
gem "kaminari"

# File Processing
gem "image_processing", "~> 1.2"

# SMS Integration
gem "twilio-ruby"
gem "httparty"

# UI & Styling
gem "bootstrap", "~> 5.3"
gem "jquery-rails"
gem "sassc-rails"

# Utilities
gem "phonelib"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Testing framework
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Environment variables
  gem "dotenv-rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Better error pages
  gem "better_errors"
  gem "binding_of_caller"

  # Letter opener for email testing
  gem "letter_opener"
end

group :test do
  # Additional testing gems
  gem "webmock"
  gem "vcr"
  gem "database_cleaner-active_record"
end


# Auditing handled via custom `AuditLog` and `Version` models in app
