# SportLink - Backend Engineering Design Document (EDD)

## 1. System Overview

### 1.1 Purpose
This document outlines the Ruby on Rails backend architecture, APIs, database design, and technical implementation details for the SportLink platform.

### 1.2 Scope
- Ruby on Rails RESTful API design and implementation
- PostgreSQL database schema and Active Record modeling
- Authentication and authorization systems using Rails conventions
- File storage and media handling with Active Storage
- Background job processing and real-time features
- Performance optimization and caching strategies
- Security implementation following Rails best practices
- Testing strategies and deployment considerations

### 1.3 System Context
The Rails backend serves as the core data and business logic layer for both web and future mobile applications, providing secure and scalable JSON APIs following Rails API conventions.

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Client    │    │  Mobile Client  │    │  Admin Panel    │
│   (React)       │    │   (Future)      │    │   (React)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │    (Nginx)      │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Rails API     │
                    │  (Rate Limiting)│
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Sidekiq      │    │  Rails Models   │    │ Active Storage  │
│ (Background)    │    │ (Business Logic)│    │ (File Upload)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │    Database     │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Redis       │    │  AWS S3/Local   │    │   Email/SMS     │
│ (Cache/Sidekiq) │    │ (Active Storage)│    │   Services      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2.2 Technology Stack

#### 2.2.1 Core Technologies
- **Framework**: Ruby on Rails 7.1+ (API-only mode)
- **Language**: Ruby 3.2+
- **Database**: PostgreSQL 15+
- **Caching**: Redis 7+ (Rails.cache + Sidekiq)
- **File Storage**: Active Storage with AWS S3/local
- **Authentication**: Devise + JWT tokens

#### 2.2.2 Essential Gems
- **Authentication**: `devise`, `devise-jwt`
- **Authorization**: `pundit` or `cancancan`
- **Serialization**: `jsonapi-serializer` or `active_model_serializers`
- **Background Jobs**: `sidekiq` + `sidekiq-web`
- **Image Processing**: `image_processing` (libvips/ImageMagick)
- **Pagination**: `kaminari` or `pagy`
- **CORS**: `rack-cors`
- **Rate Limiting**: `rack-attack`
- **Validation**: Strong Parameters + custom validators

#### 2.2.3 Development & Testing Tools
- **Testing**: RSpec + FactoryBot + Faker
- **Code Quality**: RuboCop + Brakeman (security)
- **Performance**: Bullet (N+1 queries)
- **Debugging**: `pry-rails`, `byebug`
- **API Documentation**: `rspec_api_documentation` or Swagger
- **Monitoring**: `rails_admin` for admin interface

## 3. Database Design

### 3.1 Entity Relationship Diagram

```
Users ──┐
        ├── Profiles (STI)
        │   ├── PlayerProfiles
        │   ├── CoachProfiles
        │   └── ClubProfiles
        ├── Posts ──── ActiveStorageAttachments
        ├── Comments
        ├── Likes
        ├── Connections
        ├── Messages ──── ActiveStorageAttachments
        ├── Events ──── EventRegistrations
        ├── Notifications
        └── JwtDenylist

Sports ──── UserSports
      ──── Posts
      ──── Events

ActiveStorage:
├── ActiveStorageBlobs
├── ActiveStorageAttachments
└── ActiveStorageVariantRecords
```

### 3.2 Rails Models & Database Schema

#### 3.2.1 User Model
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  enum user_type: { player: 0, coach: 1, club: 2 }
  
  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :events, foreign_key: :creator_id, dependent: :destroy
  
  # Connections
  has_many :sent_connections, class_name: 'Connection', foreign_key: :requester_id
  has_many :received_connections, class_name: 'Connection', foreign_key: :addressee_id
  
  # Messages
  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id
  has_many :received_messages, class_name: 'Message', foreign_key: :receiver_id
  
  validates :email, presence: true, uniqueness: true
  validates :phone, uniqueness: true, allow_blank: true
  validates :user_type, presence: true
  
  after_create :create_profile
  
  scope :verified, -> { where(verified: true) }
  scope :active, -> { where(active: true) }
  
  private
  
  def create_profile
    case user_type
    when 'player'
      PlayerProfile.create!(user: self)
    when 'coach'
      CoachProfile.create!(user: self)
    when 'club'
      ClubProfile.create!(user: self)
    end
  end
end
```

```ruby
# Migration: db/migrate/xxx_devise_create_users.rb
class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :phone
      t.integer :user_type,         null: false
      t.boolean :verified,          default: false
      t.boolean :active,            default: true
      t.datetime :last_sign_in_at
      
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      
      t.timestamps null: false
    end
    
    add_index :users, :email,                unique: true
    add_index :users, :phone,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :user_type
  end
end
```

#### 3.2.2 Profile Models (Single Table Inheritance)
```ruby
# app/models/profile.rb (Base class)
class Profile < ApplicationRecord
  belongs_to :user
  
  has_one_attached :profile_image
  has_one_attached :cover_image
  has_many :user_sports, through: :user
  
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, length: { maximum: 100 }
  validates :bio, length: { maximum: 5000 }
  validates :website_url, :instagram_url, :youtube_url, 
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, 
            allow_blank: true
            
  enum gender: { male: 0, female: 1, other: 2, prefer_not_to_say: 3 }
  
  scope :in_city, ->(city) { where(location_city: city) }
  scope :in_state, ->(state) { where(location_state: state) }
  
  def display_name
    read_attribute(:display_name) || "#{first_name} #{last_name}".strip
  end
  
  def privacy_settings
    super.presence || default_privacy_settings
  end
  
  private
  
  def default_privacy_settings
    {
      'profile_visibility' => 'public',
      'message_permissions' => 'connections',
      'show_email' => false,
      'show_phone' => false,
      'show_location' => true
    }
  end
end

# app/models/player_profile.rb
class PlayerProfile < Profile
  enum preferred_foot: { left: 0, right: 1, both: 2 }
  enum playing_status: { amateur: 0, semi_professional: 1, professional: 2 }
  enum availability: { available: 0, busy: 1, not_available: 2 }
  
  validates :height_cm, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validates :weight_kg, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  
  def achievements_list
    achievements.presence || []
  end
  
  def training_history_list
    training_history.presence || []
  end
end

# app/models/coach_profile.rb
class CoachProfile < Profile
  validates :experience_years, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :hourly_rate, numericality: { greater_than: 0 }, allow_blank: true
  validates :currency, inclusion: { in: %w[INR USD EUR] }
  
  def certifications_list
    certifications.presence || []
  end
  
  def coaching_history_list
    coaching_history.presence || []
  end
end

# app/models/club_profile.rb
class ClubProfile < Profile
  enum club_type: { academy: 0, club: 1, training_center: 2, school: 3 }
  
  validates :club_name, presence: true, length: { maximum: 200 }
  validates :establishment_year, numericality: { 
    greater_than: 1800, 
    less_than_or_equal_to: Date.current.year 
  }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  def facilities_list
    facilities.presence || []
  end
  
  def programs_offered_list
    programs_offered.presence || []
  end
end
```

```ruby
# Migration: db/migrate/xxx_create_profiles.rb
class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
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
    
    add_index :profiles, :user_id, unique: true
    add_index :profiles, :type
    add_index :profiles, [:location_city, :location_state]
    add_index :profiles, :club_type
    add_index :profiles, :playing_status
    add_index :profiles, :availability
  end
end
```

#### 3.2.3 Sports & User Sports Models
```ruby
# app/models/sport.rb
class Sport < ApplicationRecord
  has_many :user_sports, dependent: :destroy
  has_many :users, through: :user_sports
  has_many :posts, dependent: :nullify
  has_many :events, dependent: :nullify
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :category, presence: true
  
  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
  
  before_save { self.name = name.titleize }
end

# app/models/user_sport.rb
class UserSport < ApplicationRecord
  belongs_to :user
  belongs_to :sport
  
  enum skill_level: { beginner: 0, intermediate: 1, advanced: 2, expert: 3 }
  
  validates :user_id, uniqueness: { scope: :sport_id }
  validates :position, length: { maximum: 100 }
  validates :years_experience, numericality: { greater_than_or_equal_to: 0 }
  validates :skill_level, presence: true
  
  scope :primary, -> { where(primary: true) }
  scope :by_skill_level, ->(level) { where(skill_level: level) }
end
```

```ruby
# Migration: db/migrate/xxx_create_sports.rb
class CreateSports < ActiveRecord::Migration[7.1]
  def change
    create_table :sports, id: :uuid do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.boolean :active, default: true
      t.timestamps
    end
    
    add_index :sports, :name, unique: true
    add_index :sports, :category
    add_index :sports, :active
  end
end

# Migration: db/migrate/xxx_create_user_sports.rb
class CreateUserSports < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sports, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :sport, null: false, foreign_key: true, type: :uuid
      t.string :position
      t.integer :skill_level, default: 0, null: false
      t.integer :years_experience, default: 0
      t.boolean :primary, default: false
      t.timestamps
    end
    
    add_index :user_sports, [:user_id, :sport_id], unique: true
    add_index :user_sports, :skill_level
    add_index :user_sports, :primary
  end
end
```

#### 3.2.4 Posts Model
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :sport, optional: true
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many_attached :media_files
  
  enum post_type: { text: 0, image: 1, video: 2, link: 3, achievement: 4 }
  enum privacy_level: { public: 0, connections: 1, private: 2 }
  
  validates :content, presence: true, length: { maximum: 5000 }
  validates :post_type, presence: true
  validates :privacy_level, presence: true
  
  scope :visible_to_public, -> { where(privacy_level: 'public') }
  scope :recent, -> { order(created_at: :desc) }
  scope :boosted, -> { where(boosted: true).where('boost_expires_at > ?', Time.current) }
  scope :by_sport, ->(sport_id) { where(sport_id: sport_id) }
  
  before_save :set_boost_expiry
  after_create :increment_user_posts_count
  after_destroy :decrement_user_posts_count
  
  def boosted?
    boosted && boost_expires_at&.future?
  end
  
  def liked_by?(user)
    likes.exists?(user: user)
  end
  
  def visibility_for(current_user)
    return true if privacy_level == 'public'
    return false if current_user.nil?
    return true if user == current_user
    
    case privacy_level
    when 'connections'
      user.connected_with?(current_user)
    when 'private'
      false
    else
      false
    end
  end
  
  private
  
  def set_boost_expiry
    if boosted && boost_expires_at.nil?
      self.boost_expires_at = 7.days.from_now
    end
  end
  
  def increment_user_posts_count
    user.increment!(:posts_count)
  end
  
  def decrement_user_posts_count
    user.decrement!(:posts_count)
  end
end

# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user
  belongs_to :parent, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_id', dependent: :destroy
  
  validates :content, presence: true, length: { maximum: 1000 }
  
  scope :top_level, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :desc) }
  
  after_create :increment_post_comments_count
  after_destroy :decrement_post_comments_count
  
  private
  
  def increment_post_comments_count
    post.increment!(:comments_count)
  end
  
  def decrement_post_comments_count
    post.decrement!(:comments_count)
  end
end

# app/models/like.rb
class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true
  
  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id] }
  
  after_create :increment_likes_count
  after_destroy :decrement_likes_count
  
  private
  
  def increment_likes_count
    likeable.increment!(:likes_count)
  end
  
  def decrement_likes_count
    likeable.decrement!(:likes_count)
  end
end
```

```ruby
# Migration: db/migrate/xxx_create_posts.rb
class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :sport, null: true, foreign_key: true, type: :uuid
      t.text :content, null: false
      t.integer :post_type, default: 0, null: false
      t.integer :privacy_level, default: 0, null: false
      t.boolean :boosted, default: false
      t.datetime :boost_expires_at
      t.integer :likes_count, default: 0
      t.integer :comments_count, default: 0
      t.integer :shares_count, default: 0
      t.timestamps
    end
    
    add_index :posts, :user_id
    add_index :posts, :sport_id
    add_index :posts, :post_type
    add_index :posts, :privacy_level
    add_index :posts, [:boosted, :boost_expires_at]
    add_index :posts, :created_at
  end
end

# Migration: db/migrate/xxx_create_comments.rb
class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments, id: :uuid do |t|
      t.references :post, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :parent, null: true, foreign_key: { to_table: :comments }, type: :uuid
      t.text :content, null: false
      t.timestamps
    end
    
    add_index :comments, :post_id
    add_index :comments, :user_id
    add_index :comments, :parent_id
  end
end

# Migration: db/migrate/xxx_create_likes.rb
class CreateLikes < ActiveRecord::Migration[7.1]
  def change
    create_table :likes, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :likeable, polymorphic: true, null: false, type: :uuid
      t.timestamps
    end
    
    add_index :likes, [:user_id, :likeable_type, :likeable_id], unique: true
    add_index :likes, [:likeable_type, :likeable_id]
  end
end
```

#### 3.2.5 Connections & Messages Models
```ruby
# app/models/connection.rb
class Connection < ApplicationRecord
  belongs_to :requester, class_name: 'User'
  belongs_to :addressee, class_name: 'User'
  
  enum status: { pending: 0, accepted: 1, rejected: 2, blocked: 3 }
  
  validates :requester_id, uniqueness: { 
    scope: :addressee_id, 
    message: "Connection already exists" 
  }
  validates :message, length: { maximum: 500 }
  validate :cannot_connect_to_self
  
  scope :pending_for, ->(user) { where(addressee: user, status: 'pending') }
  scope :sent_by, ->(user) { where(requester: user) }
  scope :accepted_connections, -> { where(status: 'accepted') }
  
  after_update :update_connections_count, if: :saved_change_to_status?
  
  def self.between_users(user1, user2)
    where(
      "(requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    ).first
  end
  
  def connected?
    status == 'accepted'
  end
  
  private
  
  def cannot_connect_to_self
    errors.add(:addressee, "Cannot connect to yourself") if requester_id == addressee_id
  end
  
  def update_connections_count
    if status == 'accepted'
      requester.increment!(:connections_count)
      addressee.increment!(:connections_count)
    elsif status_before_last_save == 'accepted'
      requester.decrement!(:connections_count)
      addressee.decrement!(:connections_count)
    end
  end
end

# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  has_many_attached :attachments
  
  enum message_type: { text: 0, image: 1, file: 2 }
  
  validates :content, presence: true, length: { maximum: 2000 }
  validates :message_type, presence: true
  validate :users_are_connected, on: :create
  
  scope :between_users, ->(user1, user2) do
    where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    ).order(:created_at)
  end
  
  scope :unread, -> { where(read: false) }
  scope :unread_for, ->(user) { where(receiver: user, read: false) }
  
  after_create :update_last_message_at
  
  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end
  
  def conversation_partner(current_user)
    current_user == sender ? receiver : sender
  end
  
  private
  
  def users_are_connected
    connection = Connection.between_users(sender, receiver)
    unless connection&.connected?
      errors.add(:base, "Users must be connected to send messages")
    end
  end
  
  def update_last_message_at
    # Update both users' last_message_at timestamp for conversation sorting
    [sender, receiver].each do |user|
      user.touch(:last_message_at)
    end
  end
end
```

```ruby
# Migration: db/migrate/xxx_create_connections.rb
class CreateConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :connections, id: :uuid do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :addressee, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.integer :status, default: 0, null: false
      t.text :message
      t.timestamps
    end
    
    add_index :connections, [:requester_id, :addressee_id], unique: true
    add_index :connections, :status
    add_index :connections, :addressee_id
  end
end

# Migration: db/migrate/xxx_create_messages.rb
class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages, id: :uuid do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :receiver, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.text :content, null: false
      t.integer :message_type, default: 0, null: false
      t.boolean :read, default: false
      t.datetime :read_at
      t.timestamps
    end
    
    add_index :messages, :sender_id
    add_index :messages, :receiver_id
    add_index :messages, [:sender_id, :receiver_id]
    add_index :messages, :read
    add_index :messages, :created_at
  end
end
```

#### 3.2.6 Events & Event Registrations Models
```ruby
# app/models/event.rb
class Event < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  belongs_to :sport, optional: true
  has_many :event_registrations, dependent: :destroy
  has_many :registered_users, through: :event_registrations, source: :user
  has_one_attached :event_poster
  
  enum event_type: { tryout: 0, camp: 1, tournament: 2, workshop: 3, recruitment: 4 }
  
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 5000 }
  validates :event_type, presence: true
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date }, allow_blank: true
  validates :start_time, presence: true, if: :end_time?
  validates :end_time, comparison: { greater_than: :start_time }, allow_blank: true
  validates :max_participants, numericality: { greater_than: 0 }, allow_blank: true
  validates :fee_amount, numericality: { greater_than: 0 }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  scope :active, -> { where(active: true) }
  scope :upcoming, -> { where('start_date >= ?', Date.current) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_sport, ->(sport_id) { where(sport_id: sport_id) }
  scope :in_city, ->(city) { where(location_city: city) }
  scope :registrations_open, -> do
    where('registration_deadline IS NULL OR registration_deadline >= ?', Date.current)
  end
  
  def registration_open?
    active? && (registration_deadline.nil? || registration_deadline >= Date.current)
  end
  
  def spots_available?
    max_participants.nil? || event_registrations.count < max_participants
  end
  
  def can_register?(user)
    registration_open? && spots_available? && !registered_users.include?(user)
  end
  
  def full_location
    [location_address, location_city, location_state].compact.join(', ')
  end
  
  def duration_in_days
    return 1 if end_date.nil?
    (end_date - start_date).to_i + 1
  end
end

# app/models/event_registration.rb
class EventRegistration < ApplicationRecord
  belongs_to :event
  belongs_to :user
  
  enum status: { registered: 0, confirmed: 1, cancelled: 2, attended: 3 }
  
  validates :user_id, uniqueness: { scope: :event_id }
  validates :notes, length: { maximum: 1000 }
  validate :event_allows_registration, on: :create
  validate :user_can_register, on: :create
  
  scope :active, -> { where.not(status: 'cancelled') }
  scope :for_event, ->(event) { where(event: event) }
  
  after_create :send_confirmation_email
  after_update :send_status_update_email, if: :saved_change_to_status?
  
  private
  
  def event_allows_registration
    unless event&.registration_open?
      errors.add(:event, "Registration is not open for this event")
    end
  end
  
  def user_can_register
    unless event&.spots_available?
      errors.add(:event, "No spots available for this event")
    end
  end
  
  def send_confirmation_email
    EventMailer.registration_confirmation(self).deliver_later
  end
  
  def send_status_update_email
    EventMailer.status_update(self).deliver_later
  end
end
```

```ruby
# Migration: db/migrate/xxx_create_events.rb
class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events, id: :uuid do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :sport, null: true, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.text :description
      t.integer :event_type, null: false
      t.text :location_address
      t.string :location_city
      t.string :location_state
      t.date :start_date, null: false
      t.date :end_date
      t.time :start_time
      t.time :end_time
      t.integer :max_participants
      t.date :registration_deadline
      t.text :requirements
      t.string :contact_email
      t.string :contact_phone
      t.boolean :paid, default: false
      t.decimal :fee_amount, precision: 10, scale: 2
      t.string :currency, default: 'INR'
      t.boolean :active, default: true
      t.timestamps
    end
    
    add_index :events, :creator_id
    add_index :events, :sport_id
    add_index :events, :event_type
    add_index :events, [:location_city, :location_state]
    add_index :events, :start_date
    add_index :events, :active
    add_index :events, :registration_deadline
  end
end

# Migration: db/migrate/xxx_create_event_registrations.rb
class CreateEventRegistrations < ActiveRecord::Migration[7.1]
  def change
    create_table :event_registrations, id: :uuid do |t|
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :status, default: 0, null: false
      t.text :notes
      t.timestamps
    end
    
    add_index :event_registrations, [:event_id, :user_id], unique: true
    add_index :event_registrations, :status
  end
end
```

### 3.3 Database Optimization & Indexing

#### 3.3.1 Rails Migration Indexes (Already included above)
All necessary indexes are included in the migration files above, following Rails conventions:

- **Primary Keys**: UUIDs with automatic indexing
- **Foreign Keys**: Automatic indexing via `references` and `foreign_key`
- **Unique Constraints**: Email, phone, connection pairs, etc.
- **Query Optimization**: Composite indexes for common query patterns

#### 3.3.2 Additional Performance Indexes
```ruby
# Migration: db/migrate/xxx_add_performance_indexes.rb
class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Feed query optimization
    add_index :posts, [:user_id, :created_at], order: { created_at: :desc }
    add_index :posts, [:privacy_level, :created_at], order: { created_at: :desc }
    
    # Search optimization
    add_index :profiles, [:location_city, :location_state, :type]
    add_index :profiles, "to_tsvector('english', first_name || ' ' || last_name)", 
              using: :gin, name: 'index_profiles_on_full_name_search'
    
    # Connection queries
    add_index :connections, [:status, :created_at], order: { created_at: :desc }
    
    # Message queries
    add_index :messages, [:sender_id, :receiver_id, :created_at]
    add_index :messages, [:receiver_id, :read, :created_at]
    
    # Event queries
    add_index :events, [:active, :start_date], where: "active = true"
    add_index :events, [:location_city, :event_type, :start_date]
  end
end
```

#### 3.3.3 Query Optimization Strategies
```ruby
# app/models/concerns/optimized_queries.rb
module OptimizedQueries
  extend ActiveSupport::Concern
  
  # Optimized feed query with includes to avoid N+1
  def self.user_feed(user, page: 1, per_page: 20)
    connected_user_ids = user.connected_user_ids
    
    Post.includes(:user, :sport, profile: :profile_image_attachment)
        .where(user_id: [user.id] + connected_user_ids)
        .where(privacy_level: ['public', 'connections'])
        .or(Post.where(user_id: user.id)) # Include own private posts
        .order(created_at: :desc)
        .page(page)
        .per(per_page)
  end
  
  # Optimized search with full-text search
  def self.search_profiles(query, filters = {})
    scope = Profile.includes(:user, :profile_image_attachment)
    
    if query.present?
      scope = scope.where(
        "to_tsvector('english', first_name || ' ' || last_name) @@ plainto_tsquery(?)",
        query
      )
    end
    
    scope = scope.where(location_city: filters[:city]) if filters[:city].present?
    scope = scope.where(type: "#{filters[:user_type].titleize}Profile") if filters[:user_type].present?
    
    scope.limit(50)
  end
end
```

## 4. Rails API Design

### 4.1 API Architecture & Configuration
```ruby
# config/application.rb
module SportLink
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    
    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'localhost:3000', 'sportlink.com'
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end
    
    # Active Storage configuration
    config.active_storage.variant_processor = :vips
  end
end

# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'api/v1/auth/registrations',
    sessions: 'api/v1/auth/sessions'
  }
  
  namespace :api do
    namespace :v1 do
      # Authentication routes
      namespace :auth do
        post :login, to: 'sessions#create'
        delete :logout, to: 'sessions#destroy'
        post :refresh, to: 'sessions#refresh'
        post :register, to: 'registrations#create'
        post :forgot_password, to: 'passwords#create'
        put :reset_password, to: 'passwords#update'
      end
      
      # User and Profile routes
      resources :users, only: [:show, :index] do
        resources :posts, only: [:index]
        resources :events, only: [:index]
      end
      
      resources :profiles, only: [:show, :update] do
        member do
          patch :upload_profile_image
          patch :upload_cover_image
        end
      end
      
      # Core feature routes
      resources :posts do
        member do
          post :like
          delete :unlike
          post :boost
        end
        resources :comments, except: [:show]
      end
      
      resources :connections, only: [:index, :create, :update, :destroy] do
        collection do
          get :requests
          get :sent
        end
      end
      
      resources :messages, only: [:index, :create] do
        collection do
          get :conversations
        end
        member do
          patch :mark_as_read
        end
      end
      
      resources :events do
        member do
          post :register
          delete :unregister
        end
        resources :registrations, only: [:index, :show, :update]
      end
      
      # Search and discovery
      get :search, to: 'search#index'
      resources :sports, only: [:index, :show]
      
      # Utility routes
      get :feed, to: 'feed#index'
      resources :notifications, only: [:index, :update]
    end
  end
  
  # Admin routes (if needed)
  namespace :admin do
    resources :users
    resources :posts
    resources :events
  end
  
  # Health check
  get :health, to: 'health#check'
end
```

### 4.2 Base Controller & Authentication
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  
  private
  
  def render_not_found(exception)
    render json: {
      error: {
        code: 'NOT_FOUND',
        message: exception.message,
        details: []
      }
    }, status: :not_found
  end
  
  def render_unprocessable_entity(exception)
    render json: {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'The provided data is invalid',
        details: exception.record.errors.full_messages
      }
    }, status: :unprocessable_entity
  end
  
  def render_forbidden
    render json: {
      error: {
        code: 'FORBIDDEN',
        message: 'You are not authorized to perform this action'
      }
    }, status: :forbidden
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:user_type, :first_name, :last_name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone])
  end
end

# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  include Pagy::Backend
  
  protected
  
  def render_success(data = nil, message = nil, status = :ok)
    response = { success: true }
    response[:message] = message if message
    response[:data] = data if data
    
    render json: response, status: status
  end
  
  def render_error(message, code = 'ERROR', status = :bad_request, details = [])
    render json: {
      success: false,
      error: {
        code: code,
        message: message,
        details: details,
        timestamp: Time.current.iso8601
      }
    }, status: status
  end
  
  def paginate_and_render(collection, serializer_class = nil, **options)
    pagy, records = pagy(collection, items: params[:per_page] || 20)
    
    serialized_data = if serializer_class
      serializer_class.new(records, **options).serializable_hash[:data]
    else
      records
    end
    
    render_success({
      items: serialized_data,
      pagination: {
        current_page: pagy.page,
        total_pages: pagy.pages,
        total_count: pagy.count,
        per_page: pagy.items,
        has_next_page: pagy.next.present?,
        has_prev_page: pagy.prev.present?
      }
    })
  end
end
```

### 4.3 Authentication Controllers & Serializers

#### 4.3.1 Authentication Controllers
```ruby
# app/controllers/api/v1/auth/registrations_controller.rb
class Api::V1::Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  
  private
  
  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        success: true,
        message: 'Registration successful. Please verify your email.',
        data: {
          user: UserSerializer.new(resource).serializable_hash[:data][:attributes]
        }
      }, status: :created
    else
      render json: {
        success: false,
        error: {
          code: 'REGISTRATION_FAILED',
          message: 'Registration failed',
          details: resource.errors.full_messages
        }
      }, status: :unprocessable_entity
    end
  end
  
  def sign_up_params
    params.require(:user).permit(:email, :password, :user_type, :phone)
  end
end

# app/controllers/api/v1/auth/sessions_controller.rb
class Api::V1::Auth::SessionsController < Devise::SessionsController
  respond_to :json
  
  def create
    user = User.find_by(email: params[:user][:email])
    
    if user&.valid_password?(params[:user][:password])
      token = user.generate_jwt
      render json: {
        success: true,
        message: 'Login successful',
        data: {
          user: UserSerializer.new(user).serializable_hash[:data][:attributes],
          token: token
        }
      }, status: :ok
    else
      render json: {
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password'
        }
      }, status: :unauthorized
    end
  end
  
  def destroy
    if current_user
      current_user.jwt_denylist.create(jti: decoded_token['jti'], exp: decoded_token['exp'])
      render json: {
        success: true,
        message: 'Logged out successfully'
      }, status: :ok
    else
      render json: {
        success: false,
        error: {
          code: 'NOT_AUTHENTICATED',
          message: 'User not authenticated'
        }
      }, status: :unauthorized
    end
  end
  
  private
  
  def decoded_token
    @decoded_token ||= JWT.decode(request.headers['Authorization']&.split(' ')&.last, 
                                  Rails.application.credentials.devise_jwt_secret_key).first
  end
end
```

#### 4.3.2 Core Feature Controllers
```ruby
# app/controllers/api/v1/posts_controller.rb
class Api::V1::PostsController < Api::V1::BaseController
  before_action :set_post, only: [:show, :update, :destroy, :like, :unlike, :boost]
  
  def index
    posts = Post.includes(:user, :sport, media_files_attachments: :blob)
                .visible_to_user(current_user)
                .recent
    
    posts = posts.by_sport(params[:sport_id]) if params[:sport_id].present?
    posts = posts.where(user_id: params[:user_id]) if params[:user_id].present?
    
    paginate_and_render(posts, PostSerializer, current_user: current_user)
  end
  
  def show
    authorize @post
    render_success(PostSerializer.new(@post, current_user: current_user).serializable_hash[:data][:attributes])
  end
  
  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      render_success(
        PostSerializer.new(@post, current_user: current_user).serializable_hash[:data][:attributes],
        'Post created successfully',
        :created
      )
    else
      render_error('Failed to create post', 'VALIDATION_ERROR', :unprocessable_entity, @post.errors.full_messages)
    end
  end
  
  def update
    authorize @post
    
    if @post.update(post_params)
      render_success(
        PostSerializer.new(@post, current_user: current_user).serializable_hash[:data][:attributes],
        'Post updated successfully'
      )
    else
      render_error('Failed to update post', 'VALIDATION_ERROR', :unprocessable_entity, @post.errors.full_messages)
    end
  end
  
  def destroy
    authorize @post
    
    if @post.destroy
      render_success(nil, 'Post deleted successfully')
    else
      render_error('Failed to delete post')
    end
  end
  
  def like
    authorize @post
    
    like = @post.likes.find_or_initialize_by(user: current_user)
    
    if like.persisted?
      render_error('Post already liked', 'ALREADY_LIKED', :bad_request)
    elsif like.save
      render_success({ likes_count: @post.reload.likes_count }, 'Post liked successfully')
    else
      render_error('Failed to like post')
    end
  end
  
  def unlike
    authorize @post
    
    like = @post.likes.find_by(user: current_user)
    
    if like&.destroy
      render_success({ likes_count: @post.reload.likes_count }, 'Post unliked successfully')
    else
      render_error('Post not liked', 'NOT_LIKED', :bad_request)
    end
  end
  
  def boost
    authorize @post
    
    if @post.update(boosted: true, boost_expires_at: 7.days.from_now)
      render_success(nil, 'Post boosted successfully')
    else
      render_error('Failed to boost post')
    end
  end
  
  private
  
  def set_post
    @post = Post.find(params[:id])
  end
  
  def post_params
    params.require(:post).permit(:content, :post_type, :sport_id, :privacy_level, media_files: [])
  end
end

# app/controllers/api/v1/profiles_controller.rb
class Api::V1::ProfilesController < Api::V1::BaseController
  before_action :set_profile, only: [:show, :update, :upload_profile_image, :upload_cover_image]
  
  def show
    authorize @profile
    
    serializer_class = case @profile.type
                      when 'PlayerProfile'
                        PlayerProfileSerializer
                      when 'CoachProfile'
                        CoachProfileSerializer
                      when 'ClubProfile'
                        ClubProfileSerializer
                      else
                        ProfileSerializer
                      end
    
    render_success(serializer_class.new(@profile, current_user: current_user).serializable_hash[:data][:attributes])
  end
  
  def update
    authorize @profile
    
    if @profile.update(profile_params)
      render_success(
        ProfileSerializer.new(@profile).serializable_hash[:data][:attributes],
        'Profile updated successfully'
      )
    else
      render_error('Failed to update profile', 'VALIDATION_ERROR', :unprocessable_entity, @profile.errors.full_messages)
    end
  end
  
  def upload_profile_image
    authorize @profile
    
    if params[:image].present? && @profile.profile_image.attach(params[:image])
      render_success({ profile_image_url: url_for(@profile.profile_image) }, 'Profile image uploaded successfully')
    else
      render_error('Failed to upload profile image')
    end
  end
  
  def upload_cover_image
    authorize @profile
    
    if params[:image].present? && @profile.cover_image.attach(params[:image])
      render_success({ cover_image_url: url_for(@profile.cover_image) }, 'Cover image uploaded successfully')
    else
      render_error('Failed to upload cover image')
    end
  end
  
  private
  
  def set_profile
    @profile = if params[:id] == 'me'
                current_user.profile
              else
                Profile.find(params[:id])
              end
  end
  
  def profile_params
    permitted_params = [:first_name, :last_name, :display_name, :bio, :date_of_birth, :gender,
                       :location_city, :location_state, :location_country, :website_url,
                       :instagram_url, :youtube_url, privacy_settings: {}]
    
    case @profile.type
    when 'PlayerProfile'
      permitted_params += [:height_cm, :weight_kg, :preferred_foot, :playing_status, :availability,
                          achievements: [], training_history: []]
    when 'CoachProfile'
      permitted_params += [:experience_years, :coaching_philosophy, :hourly_rate, :currency,
                          :available_for_hire, certifications: [], coaching_history: []]
    when 'ClubProfile'
      permitted_params += [:club_name, :club_type, :establishment_year, :contact_person,
                          :contact_email, :contact_phone, :address,
                          facilities: [], programs_offered: []]
    end
    
    params.require(:profile).permit(permitted_params)
  end
end
```

### 4.4 Serializers & Additional Controllers

#### 4.4.1 Serializers
```ruby
# app/serializers/user_serializer.rb
class UserSerializer
  include JSONAPI::Serializer
  
  attributes :id, :email, :user_type, :verified, :active, :created_at
  
  attribute :profile do |user, params|
    if user.profile
      case user.profile.type
      when 'PlayerProfile'
        PlayerProfileSerializer.new(user.profile, params).serializable_hash[:data][:attributes]
      when 'CoachProfile'
        CoachProfileSerializer.new(user.profile, params).serializable_hash[:data][:attributes]
      when 'ClubProfile'
        ClubProfileSerializer.new(user.profile, params).serializable_hash[:data][:attributes]
      end
    end
  end
end

# app/serializers/post_serializer.rb
class PostSerializer
  include JSONAPI::Serializer
  
  attributes :id, :content, :post_type, :privacy_level, :likes_count, 
            :comments_count, :created_at, :updated_at
  
  attribute :author do |post|
    {
      id: post.user.id,
      name: post.user.profile&.display_name || post.user.email,
      user_type: post.user.user_type,
      profile_image_url: post.user.profile&.profile_image&.attached? ? 
        Rails.application.routes.url_helpers.url_for(post.user.profile.profile_image) : nil
    }
  end
  
  attribute :sport do |post|
    post.sport ? { id: post.sport.id, name: post.sport.name } : nil
  end
  
  attribute :media_files do |post|
    post.media_files.map do |file|
      {
        id: file.id,
        filename: file.filename.to_s,
        content_type: file.content_type,
        url: Rails.application.routes.url_helpers.url_for(file)
      }
    end
  end
  
  attribute :user_interaction do |post, params|
    current_user = params[:current_user]
    if current_user
      {
        liked: post.likes.exists?(user: current_user),
        can_edit: post.user == current_user
      }
    else
      { liked: false, can_edit: false }
    end
  end
end
```

## 5. Security Implementation

### 5.1 Authentication & Authorization with Devise-JWT

#### 5.1.1 JWT Configuration
```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.devise_jwt_secret_key
    jwt.dispatch_requests = [
      ['POST', %r{^/api/v1/auth/login$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/v1/auth/logout$}]
    ]
    jwt.expiration_time = 1.day.to_i
  end
end

# app/models/jwt_denylist.rb
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist
  
  self.table_name = 'jwt_denylist'
end

# Migration for JWT denylist
class CreateJwtDenylist < ActiveRecord::Migration[7.1]
  def change
    create_table :jwt_denylist, id: :uuid do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
      t.timestamps
    end
    
    add_index :jwt_denylist, :jti
    add_index :jwt_denylist, :exp
  end
end
```

#### 5.1.2 Authorization with Pundit
```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record
  
  def initialize(user, record)
    @user = user
    @record = record
  end
  
  def index?
    false
  end
  
  def show?
    false
  end
  
  def create?
    false
  end
  
  def update?
    false
  end
  
  def destroy?
    false
  end
  
  protected
  
  def owner?
    record.user == user
  end
  
  def connected?
    return false unless user
    Connection.between_users(user, record.user)&.connected?
  end
end

# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def show?
    case record.privacy_level
    when 'public'
      true
    when 'connections'
      owner? || connected?
    when 'private'
      owner?
    else
      false
    end
  end
  
  def create?
    user.present?
  end
  
  def update?
    owner?
  end
  
  def destroy?
    owner?
  end
  
  def like?
    user.present? && show?
  end
  
  def boost?
    owner? && user.premium?
  end
end

# app/policies/profile_policy.rb
class ProfilePolicy < ApplicationPolicy
  def show?
    case record.privacy_settings['profile_visibility']
    when 'public'
      true
    when 'connections'
      owner? || connected?
    when 'private'
      owner?
    else
      true # default to public
    end
  end
  
  def update?
    owner?
  end
end
```

### 5.2 Rate Limiting with Rack::Attack

#### 5.2.1 Rate Limiting Configuration
```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle all requests by IP (60rpm)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?('/health')
  end
  
  # Throttle login attempts by email
  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      req.params['user']['email'].presence
    end
  end
  
  # Throttle registration attempts by IP
  throttle('register/ip', limit: 3, period: 1.hour) do |req|
    if req.path == '/api/v1/auth/register' && req.post?
      req.ip
    end
  end
  
  # Throttle API requests for authenticated users
  throttle('api/user', limit: 300, period: 5.minutes) do |req|
    if req.path.start_with?('/api/') && req.env['warden']&.user
      req.env['warden'].user.id
    end
  end
  
  # Block specific endpoints for excessive use
  blocklist('block-spam-posts') do |req|
    # Block if more than 10 posts in 1 minute
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 1.minute, bantime: 10.minutes) do
      req.path == '/api/v1/posts' && req.post?
    end
  end
end
```

### 5.3 Input Validation & Sanitization

#### 5.3.1 Strong Parameters & Custom Validators
```ruby
# app/validators/phone_validator.rb
class PhoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    
    unless value.match?(/\A\+?[\d\s\-\(\)]{10,15}\z/)
      record.errors.add(attribute, 'is not a valid phone number')
    end
  end
end

# app/validators/url_validator.rb
class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    
    uri = URI.parse(value)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      record.errors.add(attribute, 'is not a valid URL')
    end
  rescue URI::InvalidURIError
    record.errors.add(attribute, 'is not a valid URL')
  end
end

# Enhanced User model with validation
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, phone: true, uniqueness: true, allow_blank: true
  validates :user_type, inclusion: { in: %w[player coach club] }
  
  before_save { self.email = email.downcase }
  
  def generate_jwt
    JWT.encode(
      {
        sub: id,
        scp: 'user',
        aud: nil,
        iat: Time.current.to_i,
        exp: 24.hours.from_now.to_i,
        jti: SecureRandom.uuid
      },
      Rails.application.credentials.devise_jwt_secret_key
    )
  end
end
```

## 6. Performance Optimization

### 6.1 Caching Strategy with Rails Cache

#### 6.1.1 Redis Configuration
```ruby
# config/environments/production.rb
Rails.application.configure do
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    expires_in: 1.hour,
    namespace: 'sportlink',
    race_condition_ttl: 5.seconds
  }
end

# app/models/concerns/cacheable.rb
module Cacheable
  extend ActiveSupport::Concern
  
  included do
    after_update :expire_cache
    after_destroy :expire_cache
  end
  
  def cache_key_with_version
    "#{cache_key}/#{cache_version}"
  end
  
  private
  
  def expire_cache
    Rails.cache.delete(cache_key_with_version)
  end
end
```

#### 6.1.2 Model Caching
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include Cacheable
  
  # Cache expensive operations
  def cached_like_count
    Rails.cache.fetch("#{cache_key_with_version}/likes_count", expires_in: 5.minutes) do
      likes.count
    end
  end
  
  def self.cached_feed_for_user(user, page: 1, per_page: 20)
    cache_key = "user_feed/#{user.id}/#{user.updated_at.to_i}/page_#{page}"
    
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      user_feed(user, page: page, per_page: per_page).to_a
    end
  end
  
  # Bust cache when user's connections change
  def self.bust_feed_cache_for_user(user)
    Rails.cache.delete_matched("user_feed/#{user.id}/*")
  end
end

# app/models/user.rb
class User < ApplicationRecord
  after_update :bust_related_caches
  
  def cached_profile_with_stats
    Rails.cache.fetch("#{cache_key_with_version}/profile_stats", expires_in: 1.hour) do
      {
        profile: profile,
        posts_count: posts.count,
        connections_count: connections_count,
        events_created: events.count
      }
    end
  end
  
  private
  
  def bust_related_caches
    Post.bust_feed_cache_for_user(self)
    Rails.cache.delete_matched("search_profiles/*") if saved_change_to_attribute?(:updated_at)
  end
end
```

### 6.2 Database Query Optimization

#### 6.2.1 N+1 Query Prevention
```ruby
# app/controllers/concerns/query_optimization.rb
module QueryOptimization
  extend ActiveSupport::Concern
  
  # Optimized includes for common queries
  def posts_with_associations
    Post.includes(
      :sport,
      :likes,
      user: { profile: { profile_image_attachment: :blob } },
      media_files_attachments: :blob
    )
  end
  
  def users_with_profiles
    User.includes(
      profile: { profile_image_attachment: :blob }
    )
  end
  
  def events_with_details
    Event.includes(
      :sport,
      :event_registrations,
      creator: { profile: :profile_image_attachment },
      event_poster_attachment: :blob
    )
  end
end

# app/models/concerns/optimized_scopes.rb
module OptimizedScopes
  extend ActiveSupport::Concern
  
  included do
    # Counter cache for better performance
    belongs_to :user, counter_cache: true, optional: false
    
    # Efficient scopes
    scope :with_stats, -> do
      select(
        "#{table_name}.*",
        "(SELECT COUNT(*) FROM likes WHERE likeable_type = '#{name}' AND likeable_id = #{table_name}.id) as likes_count",
        "(SELECT COUNT(*) FROM comments WHERE post_id = #{table_name}.id) as comments_count"
      )
    end
  end
end
```

#### 6.2.2 Background Job Processing
```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  
  def perform(*args)
    # Performance monitoring
    start_time = Time.current
    super
  ensure
    duration = Time.current - start_time
    Rails.logger.info "Job #{self.class.name} completed in #{duration}s"
  end
end

# app/jobs/feed_cache_job.rb
class FeedCacheJob < ApplicationJob
  queue_as :default
  
  def perform(user_id)
    user = User.find(user_id)
    
    # Pre-warm feed cache
    (1..5).each do |page|
      Post.cached_feed_for_user(user, page: page)
    end
  end
end

# app/jobs/email_notification_job.rb
class EmailNotificationJob < ApplicationJob
  queue_as :notifications
  
  def perform(user_id, notification_type, data = {})
    user = User.find(user_id)
    
    case notification_type
    when 'connection_request'
      UserMailer.connection_request(user, data[:requester]).deliver_now
    when 'event_reminder'
      EventMailer.reminder(user, data[:event]).deliver_now
    end
  end
end

# Configure Sidekiq
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  
  config.cron 'feed_warmup' => {
    'cron' => '0 6 * * *', # 6 AM daily
    'class' => 'FeedWarmupJob'
  }
end
```

## 7. Testing Strategy

### 7.1 RSpec Configuration

#### 7.1.1 Test Setup
```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  # Include authentication helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
  
  # Database cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

# spec/support/api_helpers.rb
module ApiHelpers
  def json_response
    JSON.parse(response.body)
  end
  
  def auth_headers(user)
    token = user.generate_jwt
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
```

#### 7.1.2 Factory Bot Setup
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    user_type { 'player' }
    verified { true }
    active { true }
    
    trait :coach do
      user_type { 'coach' }
    end
    
    trait :club do
      user_type { 'club' }
    end
    
    after(:create) do |user|
      create(:profile, user: user)
    end
  end
end

# spec/factories/profiles.rb
FactoryBot.define do
  factory :profile do
    user
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    bio { Faker::Lorem.paragraph }
    location_city { 'Mumbai' }
    location_state { 'Maharashtra' }
    
    factory :player_profile, class: 'PlayerProfile' do
      type { 'PlayerProfile' }
      height_cm { 175 }
      weight_kg { 70 }
      preferred_foot { 'right' }
      playing_status { 'amateur' }
    end
    
    factory :coach_profile, class: 'CoachProfile' do
      type { 'CoachProfile' }
      experience_years { 5 }
      coaching_philosophy { 'Focus on technique and teamwork' }
    end
    
    factory :club_profile, class: 'ClubProfile' do
      type { 'ClubProfile' }
      club_name { 'Mumbai Football Club' }
      club_type { 'club' }
    end
  end
end

# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    user
    content { Faker::Lorem.paragraph }
    post_type { 'text' }
    privacy_level { 'public' }
    
    trait :with_sport do
      sport
    end
    
    trait :boosted do
      boosted { true }
      boost_expires_at { 7.days.from_now }
    end
  end
end
```

### 7.2 Model Testing

#### 7.2.1 Model Specs
```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_inclusion_of(:user_type).in_array(%w[player coach club]) }
  end
  
  describe 'associations' do
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:sent_connections).class_name('Connection') }
  end
  
  describe 'callbacks' do
    it 'creates profile after user creation' do
      user = create(:user, user_type: 'player')
      expect(user.profile).to be_a(PlayerProfile)
    end
  end
  
  describe '#generate_jwt' do
    let(:user) { create(:user) }
    
    it 'generates a valid JWT token' do
      token = user.generate_jwt
      expect(token).to be_present
      
      decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
      expect(decoded['sub']).to eq(user.id)
    end
  end
end

# spec/models/post_spec.rb
RSpec.describe Post, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(5000) }
    it { should validate_presence_of(:post_type) }
  end
  
  describe 'scopes' do
    let!(:public_post) { create(:post, privacy_level: 'public') }
    let!(:private_post) { create(:post, privacy_level: 'private') }
    
    describe '.visible_to_public' do
      it 'returns only public posts' do
        expect(Post.visible_to_public).to include(public_post)
        expect(Post.visible_to_public).not_to include(private_post)
      end
    end
  end
  
  describe '#visibility_for' do
    let(:author) { create(:user) }
    let(:other_user) { create(:user) }
    let(:post) { create(:post, user: author, privacy_level: 'connections') }
    
    context 'when users are connected' do
      before do
        create(:connection, requester: author, addressee: other_user, status: 'accepted')
      end
      
      it 'returns true' do
        expect(post.visibility_for(other_user)).to be_truthy
      end
    end
    
    context 'when users are not connected' do
      it 'returns false' do
        expect(post.visibility_for(other_user)).to be_falsey
      end
    end
  end
end
```

### 7.3 Controller Testing

#### 7.3.1 Request Specs
```ruby
# spec/requests/api/v1/posts_spec.rb
RSpec.describe 'Posts API', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  
  describe 'GET /api/v1/posts' do
    let!(:posts) { create_list(:post, 3, privacy_level: 'public') }
    
    it 'returns all public posts' do
      get '/api/v1/posts', headers: headers
      
      expect(response).to have_http_status(:ok)
      expect(json_response['success']).to be(true)
      expect(json_response['data']['items'].size).to eq(3)
    end
    
    context 'with sport filter' do
      let(:sport) { create(:sport) }
      let!(:sport_post) { create(:post, sport: sport) }
      
      it 'filters posts by sport' do
        get '/api/v1/posts', params: { sport_id: sport.id }, headers: headers
        
        expect(response).to have_http_status(:ok)
        expect(json_response['data']['items'].size).to eq(1)
      end
    end
  end
  
  describe 'POST /api/v1/posts' do
    let(:valid_params) do
      {
        post: {
          content: 'Great training session today!',
          post_type: 'text',
          privacy_level: 'public'
        }
      }
    end
    
    context 'with valid parameters' do
      it 'creates a new post' do
        expect {
          post '/api/v1/posts', params: valid_params, headers: headers
        }.to change(Post, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be(true)
        expect(json_response['message']).to eq('Post created successfully')
      end
    end
    
    context 'with invalid parameters' do
      it 'returns validation errors' do
        invalid_params = { post: { content: '' } }
        
        post '/api/v1/posts', params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['success']).to be(false)
        expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
      end
    end
  end
  
  describe 'POST /api/v1/posts/:id/like' do
    let(:post_to_like) { create(:post) }
    
    context 'when not already liked' do
      it 'likes the post' do
        expect {
          post "/api/v1/posts/#{post_to_like.id}/like", headers: headers
        }.to change(Like, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Post liked successfully')
      end
    end
    
    context 'when already liked' do
      before do
        create(:like, user: user, likeable: post_to_like)
      end
      
      it 'returns error' do
        post "/api/v1/posts/#{post_to_like.id}/like", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']['code']).to eq('ALREADY_LIKED')
      end
    end
  end
end

# spec/requests/api/v1/auth_spec.rb
RSpec.describe 'Authentication API', type: :request do
  describe 'POST /api/v1/auth/register' do
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          user_type: 'player'
        }
      }
    end
    
    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/auth/register', params: valid_params
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(json_response['success']).to be(true)
        expect(json_response['message']).to include('Registration successful')
      end
    end
    
    context 'with duplicate email' do
      let!(:existing_user) { create(:user, email: 'newuser@example.com') }
      
      it 'returns validation error' do
        post '/api/v1/auth/register', params: valid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']['details']).to include('Email has already been taken')
      end
    end
  end
  
  describe 'POST /api/v1/auth/login' do
    let(:user) { create(:user, password: 'password123') }
    
    context 'with valid credentials' do
      it 'returns authentication token' do
        post '/api/v1/auth/login', params: {
          user: { email: user.email, password: 'password123' }
        }
        
        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be(true)
        expect(json_response['data']['token']).to be_present
        expect(json_response['data']['user']['email']).to eq(user.email)
      end
    end
    
    context 'with invalid credentials' do
      it 'returns authentication error' do
        post '/api/v1/auth/login', params: {
          user: { email: user.email, password: 'wrongpassword' }
        }
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']['code']).to eq('INVALID_CREDENTIALS')
      end
    end
  end
end
```

## 8. Deployment & DevOps

### 8.1 Environment Configuration

#### 8.1.1 Environment Variables
```ruby
# config/application.yml (using figaro gem)
development:
  DATABASE_URL: "postgresql://localhost/sportlink_development"
  REDIS_URL: "redis://localhost:6379/0"
  SECRET_KEY_BASE: "development_secret_key"
  DEVISE_JWT_SECRET_KEY: "jwt_secret_key"
  AWS_ACCESS_KEY_ID: "your_aws_access_key"
  AWS_SECRET_ACCESS_KEY: "your_aws_secret_key"
  AWS_REGION: "ap-south-1"
  AWS_S3_BUCKET: "sportlink-dev-uploads"

production:
  DATABASE_URL: <%= ENV['DATABASE_URL'] %>
  REDIS_URL: <%= ENV['REDIS_URL'] %>
  SECRET_KEY_BASE: <%= ENV['SECRET_KEY_BASE'] %>
  DEVISE_JWT_SECRET_KEY: <%= ENV['DEVISE_JWT_SECRET_KEY'] %>
  AWS_ACCESS_KEY_ID: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  AWS_SECRET_ACCESS_KEY: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  AWS_S3_BUCKET: <%= ENV['AWS_S3_BUCKET'] %>
  RAILS_LOG_LEVEL: "info"
  RAILS_MAX_THREADS: "10"
```

#### 8.1.2 Database Configuration
```ruby
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: sportlink_development
  username: postgres
  password: password
  host: localhost

test:
  <<: *default
  database: sportlink_test<%= ENV['TEST_ENV_NUMBER'] %>
  username: postgres
  password: password
  host: localhost

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 10 } %>
```

### 8.2 Docker Configuration

#### 8.2.1 Dockerfile
```dockerfile
# Use Ruby 3.2 as base image
FROM ruby:3.2-alpine AS base

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    yarn \
    git \
    imagemagick \
    vips-dev

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY . .

# Precompile assets (if needed)
RUN bundle exec rails assets:precompile

# Create user for security
RUN adduser -D -s /bin/sh sportlink
RUN chown -R sportlink:sportlink /app
USER sportlink

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

#### 8.2.2 Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: sportlink_development
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  web:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/sportlink_development
      REDIS_URL: redis://redis:6379/0
    volumes:
      - .:/app
      - gem_cache:/usr/local/bundle

  sidekiq:
    build: .
    command: bundle exec sidekiq
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/sportlink_development
      REDIS_URL: redis://redis:6379/0
    volumes:
      - .:/app
      - gem_cache:/usr/local/bundle

volumes:
  postgres_data:
  redis_data:
  gem_cache:
```

### 8.3 Production Deployment

#### 8.3.1 Heroku Configuration
```ruby
# Procfile
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
release: bundle exec rails db:migrate

# config/puma.rb
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"
port ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

workers ENV.fetch("WEB_CONCURRENCY") { 2 }
preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

allow_named_arguments
```

#### 8.3.2 Production Configuration
```ruby
# config/environments/production.rb
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  
  # Logging
  config.log_level = :info
  config.log_tags = [:request_id]
  
  # Active Storage
  config.active_storage.variant_processor = :vips
  
  # Force all access to the app over SSL
  config.force_ssl = true
  
  # Security headers
  config.ssl_options = {
    redirect: { exclude: ->(request) { request.path =~ /health/ } }
  }
  
  # Mailer configuration
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV['HOST_URL'] }
  
  # CORS configuration
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins ENV['CORS_ORIGINS']&.split(',') || ['localhost:3000']
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: true
    end
  end
end
```

### 8.4 Monitoring & Health Checks

#### 8.4.1 Health Check Endpoint
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def check
    health_status = {
      status: 'OK',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || 'unknown',
      checks: {
        database: database_check,
        redis: redis_check,
        storage: storage_check
      }
    }
    
    overall_status = health_status[:checks].values.all? { |check| check[:status] == 'OK' }
    
    render json: health_status, status: overall_status ? :ok : :service_unavailable
  end
  
  private
  
  def database_check
    ActiveRecord::Base.connection.exec_query('SELECT 1')
    { status: 'OK', message: 'Database is accessible' }
  rescue => e
    { status: 'ERROR', message: e.message }
  end
  
  def redis_check
    Rails.cache.redis.ping
    { status: 'OK', message: 'Redis is accessible' }
  rescue => e
    { status: 'ERROR', message: e.message }
  end
  
  def storage_check
    # Check if Active Storage is working
    ActiveStorage::Blob.count
    { status: 'OK', message: 'Storage is accessible' }
  rescue => e
    { status: 'ERROR', message: e.message }
  end
end
```

#### 8.4.2 Application Monitoring
```ruby
# config/initializers/application_monitoring.rb
if Rails.env.production?
  # New Relic configuration
  require 'newrelic_rpm'
  
  # Custom performance monitoring
  ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |name, started, finished, unique_id, data|
    duration = finished - started
    
    if duration > 1.0 # Log slow requests
      Rails.logger.warn "Slow request: #{data[:controller]}##{data[:action]} took #{duration}s"
    end
  end
  
  # Database query monitoring
  ActiveSupport::Notifications.subscribe 'sql.active_record' do |name, started, finished, unique_id, data|
    duration = finished - started
    
    if duration > 0.5 # Log slow queries
      Rails.logger.warn "Slow query: #{data[:sql]} took #{duration}s"
    end
  end
end
```

## 9. Conclusion

This Rails backend design provides a comprehensive, secure, and scalable foundation for the SportLink platform. Key architectural highlights include:

### 9.1 Technical Excellence
- **Modern Rails 7.1**: API-only mode with best practices
- **PostgreSQL**: Robust relational database with proper indexing
- **Redis**: Caching and background job processing
- **JWT Authentication**: Secure token-based authentication with Devise
- **Active Storage**: Integrated file handling with cloud storage support

### 9.2 Scalability Features
- **Optimized Database Queries**: Proper indexing and N+1 prevention
- **Caching Strategy**: Multi-level caching with Redis
- **Background Jobs**: Sidekiq for asynchronous processing
- **Horizontal Scaling**: Stateless design ready for load balancing

### 9.3 Security Implementation
- **Authentication**: Devise with JWT tokens
- **Authorization**: Pundit for fine-grained permissions
- **Rate Limiting**: Rack::Attack for API protection
- **Input Validation**: Strong parameters and custom validators

### 9.4 Development Best Practices
- **Testing**: Comprehensive RSpec test suite
- **Code Quality**: RuboCop and Brakeman integration
- **Documentation**: Clear API documentation and code comments
- **Monitoring**: Health checks and performance monitoring

This architecture supports all features outlined in the PRD while maintaining flexibility for future enhancements and global expansion.
