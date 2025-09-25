class Vocabulary < ApplicationRecord
  belongs_to :user

  # Validations
  validates :source_text, presence: true, length: { maximum: 1000 }
  validates :target_text, presence: true, length: { maximum: 1000 }
  validates :source_language, presence: true, length: { maximum: 5 }
  validates :status, presence: true

  # Status enum for vocabulary learning progress
  enum :status, {
    offen: "offen",
    am_lernen: "am_lernen",
    gelernt: "gelernt"
  }

  # Set default status
  after_initialize :set_default_status

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def set_default_status
    self.status ||= "offen"
  end
end
