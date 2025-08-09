class Connection < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :addressee, class_name: "User"

  enum :status, { pending: 0, accepted: 1, blocked: 2 }

  validates :requester_id, presence: true
  validates :addressee_id, presence: true
  validates :status, presence: true
  validate :not_self_connection
  validates :requester_id, uniqueness: { scope: :addressee_id }

  scope :between, ->(user_a_id, user_b_id) do
    where(
      "(requester_id = :a AND addressee_id = :b) OR (requester_id = :b AND addressee_id = :a)",
      a: user_a_id, b: user_b_id
    )
  end

  scope :accepted_between, ->(user_a_id, user_b_id) { between(user_a_id, user_b_id).where(status: :accepted) }

  def self.between_users(user_a, user_b)
    between(user_a.id, user_b.id).first
  end

  # Backwards-compatible helper expected by User#connected_with?
  def connected?
    accepted?
  end

  private

  def not_self_connection
    errors.add(:base, "cannot connect to self") if requester_id == addressee_id
  end
end
