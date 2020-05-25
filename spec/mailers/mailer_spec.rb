require 'rails_helper'

RSpec.describe RailsJwtAuth::Mailer, type: :mailer do
  let(:mail_params) { {user_id: user.id.to_s } }

  describe '#confirmation_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_unconfirmed_user,
                         confirmation_token: 'abcd', confirmation_sent_at: Time.current)
    end

    let(:mail) { described_class.with(mail_params).confirmation_instructions.deliver_now }
    let(:url) { "#{RailsJwtAuth.confirmations_url}?confirmation_token=#{user.confirmation_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when confirmations_url option is defined with hash url' do
      before do
        RailsJwtAuth.confirmations_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.confirmations_url}&confirmation_token=#{user.confirmation_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when confirmation_url option is not defined' do
      it 'raises NotConfirmationsUrl exception' do
        allow(RailsJwtAuth).to receive(:confirmations_url).and_return(nil)
        expect { mail }.to raise_error(RailsJwtAuth::NotConfirmationsUrl)
      end
    end

    context 'when model has unconfirmed_email' do
      it 'sends email with correct info' do
        user.unconfirmed_email = 'new@email.com'
        user.save
        expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject'))
        expect(mail.to).to include('new@email.com')
      end
    end
  end

  describe '#email_chage_notification' do
    let(:user) { FactoryBot.create(:active_record_user) }
    let(:mail) { described_class.with(mail_params).email_change_notification.deliver_now }

    it 'sends email with notification' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq('Email change')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
    end
  end

  describe '#reset_password_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_user, reset_password_token: 'abcd',
                                             reset_password_sent_at: Time.current)
    end

    let(:mail) { described_class.with(mail_params).reset_password_instructions.deliver_now }
    let(:url) { "#{RailsJwtAuth.reset_passwords_url}?reset_password_token=#{user.reset_password_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.reset_password_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when reset_passwords_url option is defined with hash url' do
      before do
        RailsJwtAuth.reset_passwords_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.reset_passwords_url}&reset_password_token=#{user.reset_password_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when reset_passwords_url option is not defined' do
      it 'raises NotResetPasswordsUrl exception' do
        allow(RailsJwtAuth).to receive(:reset_passwords_url).and_return(nil)
        expect { mail }.to raise_error(RailsJwtAuth::NotResetPasswordsUrl)
      end
    end
  end

  describe '#password_chaged_notification' do
    let(:user) { FactoryBot.create(:active_record_user) }
    let(:mail) { described_class.with(mail_params).password_changed_notification.deliver_now }

    it 'sends email with notification' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq('Password changed')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
    end
  end

  describe 'invitation_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_user, invitation_token: 'abcd')
    end

    let(:mail) { described_class.with(mail_params).invitation_instructions.deliver_now }
    let(:url) { "#{RailsJwtAuth.invitations_url}?invitation_token=#{user.invitation_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.invitation_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when invitations_url option is defined with hash url' do
      before do
        RailsJwtAuth.invitations_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate invitation url' do
        url = "#{RailsJwtAuth.invitations_url}&invitation_token=#{user.invitation_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when invitations_url option is not defined' do
      it 'raises NotInvitationsUrl exception' do
        allow(RailsJwtAuth).to receive(:invitations_url).and_return(nil)
        expect { mail }.to raise_error(RailsJwtAuth::NotInvitationsUrl)
      end
    end
  end

  describe 'unlock_instructions' do
    let(:user) do
      FactoryBot.create(
        :active_record_user,
        locked_at: 2.minutes.ago,
        unlock_token: SecureRandom.base58(24)
      )
    end

    let(:mail) { described_class.with(mail_params).unlock_instructions.deliver_now }
    let(:url) { "#{RailsJwtAuth.unlock_url}?unlock_token=#{user.unlock_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.unlock_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when unlock_url option is defined with hash url' do
      before do
        RailsJwtAuth.unlock_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate unlock url' do
        url = "#{RailsJwtAuth.unlock_url}&unlock_token=#{user.unlock_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when unlock_url option is not defined' do
      it 'raises NotUnlockUrl exception' do
        allow(RailsJwtAuth).to receive(:unlock_url).and_return(nil)
        expect { mail }.to raise_error(RailsJwtAuth::NotUnlockUrl)
      end
    end
  end
end
