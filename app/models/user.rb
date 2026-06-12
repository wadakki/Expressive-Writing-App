class User < ApplicationRecord
  authenticates_with_sorcery!

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 },
                       confirmation: true,
                       if: -> { new_record? || password.present? }
  validates :password_confirmation, presence: true,
                                    if: -> { new_record? || password.present? }
end
