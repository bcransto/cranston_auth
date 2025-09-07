class User < ApplicationRecord
  self.primary_key = :id
  
  has_secure_password
  
  # Generate external ID for cross-service references
  before_create :generate_ids
  
  # Enums
  enum :role, { student: 0, teacher: 1, admin: 2 }
  
  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: :password_required?
  validate :validate_lasid_by_role
  
  # Callbacks
  before_save :normalize_email
  
  # Instance methods
  def soft_delete
    update(deleted_at: Time.current)
  end
  
  def restore
    update(deleted_at: nil)
  end
  
  def deleted?
    deleted_at.present?
  end
  
  def track_successful_login!
    update(
      last_login_at: Time.current,
      login_count: (login_count || 0) + 1
    )
  end
  
  # Class methods
  def self.authenticate_user(email, password)
    user = active.find_by(email: email&.downcase&.strip)
    return nil unless user&.authenticate(password)
    
    user.track_successful_login!
    user
  end
  
  private
  
  def generate_ids
    self.id ||= SecureRandom.uuid
    self.external_id ||= SecureRandom.uuid
  end
  
  def normalize_email
    self.email = email&.downcase&.strip
  end
  
  def password_required?
    new_record? || password.present?
  end
  
  def validate_lasid_by_role
    if student?
      errors.add(:lasid, "must be exactly 4 digits") unless lasid&.match?(/^\d{4}$/)
    elsif lasid.present?
      errors.add(:lasid, "must be nil for teachers and admins")
    end
  end
end