module RailsJwtAuth
  module Confirmable
    def send_confirmation_instructions
      if confirmed? && !unconfirmed_email_changed?
        errors.add(:email, I18n.t('rails_jwt_auth.errors.already_confirmed'))
        return false
      end

      self.confirmation_token = SecureRandom.base58(24)
      self.confirmation_sent_at = Time.now

      Mailer.confirmation_instructions(self).deliver if save
    end

    def confirmed?
      confirmed_at.present?
    end

    def confirm!
      self.confirmed_at = Time.now.utc

      if unconfirmed_email
        self.email = unconfirmed_email
        self.unconfirmed_email = nil
      end

      save
    end

    def skip_confirmation!
      self.confirmed_at = Time.now.utc
    end

    def confirmation_in_progress?
      !confirmed_at && confirmation_token && confirmation_sent_at &&
        (Time.now < (confirmation_sent_at + RailsJwtAuth.confirmation_expiration_time))
    end

    def self.included(base)
      if base.ancestors.include? Mongoid::Document
        base.send(:field, :email,                type: String)
        base.send(:field, :unconfirmed_email,    type: String)
        base.send(:field, :confirmation_token,   type: String)
        base.send(:field, :confirmation_sent_at, type: Time)
        base.send(:field, :confirmed_at,         type: Time)
      end

      base.send(:validate, :validate_confirmation, if: :confirmed_at_changed?)

      base.send(:after_create) do
        send_confirmation_instructions unless confirmed_at || confirmation_sent_at
      end

      base.send(:before_update) do
        if email_changed? && email_was && !confirmed_at_changed?
          self.unconfirmed_email = email
          self.email = email_was
          send_confirmation_instructions
        end
      end
    end

    private

    def validate_confirmation
      return true if !confirmed_at || email_changed?

      if confirmed_at_was
        errors.add(:email, I18n.t('rails_jwt_auth.errors.already_confirmed'))
      elsif confirmation_sent_at &&
            (confirmation_sent_at < (Time.now - RailsJwtAuth.confirmation_expiration_time))
        errors.add(:confirmation_token, I18n.t('rails_jwt_auth.errors.expired'))
      end
    end
  end
end
