class AdminInvitation < ApplicationRecord
  belongs_to :invited_by, class_name: "User"
  enum :role, { user: 0, admin: 1, moderator: 2 }

  before_validation :ensure_token_and_expiry, on: :create

  validates :email, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  private

  def ensure_token_and_expiry
    self.token ||= SecureRandom.hex(16)
    self.expires_at ||= 7.days.from_now
  end
end


