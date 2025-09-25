class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :vocabularies, dependent: :destroy

  # Admin functionality
  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }
  scope :active, -> { where(suspended: false) }
  scope :suspended, -> { where(suspended: true) }

  def admin?
    admin
  end

  def suspended?
    suspended || false
  end

  def active_for_authentication?
    super && !suspended?
  end

  def inactive_message
    suspended? ? :suspended : super
  end
end
