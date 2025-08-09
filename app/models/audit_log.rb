class AuditLog < ApplicationRecord
  belongs_to :admin_user, class_name: "User"

  validates :action, presence: true
  validates :record_type, presence: true
  validates :record_id, presence: true
end


