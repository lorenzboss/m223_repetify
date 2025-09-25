class Vocabulary < ApplicationRecord
  belongs_to :user

  # Validations
  validates :source_text, presence: true, length: { maximum: 1000 }
  validates :target_text, presence: true, length: { maximum: 1000 }
  validates :source_language, presence: true, length: { maximum: 5 }
  validates :status, presence: true

  # Status enum for vocabulary learning progress (English in DB)
  enum :status, {
    open: "open",
    learning: "learning",
    learned: "learned"
  }

  # Set default status and normalize source_language
  after_initialize :set_defaults
  before_save :normalize_source_language

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }

  # Method to get German status display
  def status_german
    case status
    when "open" then "Offen"
    when "learning" then "Am Lernen"
    when "learned" then "Gelernt"
    else status
    end
  end

  private

  def set_defaults
    self.status ||= "open"
  end

  def normalize_source_language
    self.source_language = source_language&.downcase
  end
end
