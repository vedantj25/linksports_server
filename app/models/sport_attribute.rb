class SportAttribute < ApplicationRecord
  has_many :sport_attribute_mappings, dependent: :destroy
  has_many :sports, through: :sport_attribute_mappings

  validates :key, presence: true, uniqueness: { case_sensitive: false }
  validates :label, presence: true
  validates :field_type, inclusion: { in: %w[string select multi_select] }
  validate :options_presence_for_select

  private

  def options_presence_for_select
    return unless %w[select multi_select].include?(field_type)
    if options.blank? || options.reject(&:blank?).empty?
      errors.add(:options, "must include at least one option for select types")
    end
  end
end
