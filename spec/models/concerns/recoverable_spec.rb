require 'rails_helper'

describe RailsJwtAuth::Recoverable do
  %w(ActiveRecord Mongoid).each do |orm|
    let(:user) { FactoryGirl.create("#{orm.underscore}_user") }

    context "when use #{orm}" do
      describe '#attributes' do
        it { expect(user).to respond_to(:reset_password_token) }
        it { expect(user).to respond_to(:reset_password_sent_at) }
      end

      describe '#reset_password_in_progress?' do
        it 'returns if reset password is in progress' do
          expect(user.reset_password_in_progress?).to be_falsey

          user.reset_password_token = 'abcd'
          user.reset_password_sent_at = Time.now
          expect(user.reset_password_in_progress?).to be_truthy
        end
      end

      describe '#send_reset_password_instructions' do
        before :all do
          class Mock
            def deliver
            end
          end
        end

        it 'fills reset password fields' do
          mock = Mock.new
          allow(RailsJwtAuth::Mailer).to receive(:reset_password_instructions).and_return(mock)
          user.send_reset_password_instructions
          user.reload
          expect(user.reset_password_token).not_to be_nil
          expect(user.reset_password_sent_at).not_to be_nil
        end

        it 'sends reset password email' do
          mock = Mock.new
          allow(RailsJwtAuth::Mailer).to receive(:reset_password_instructions).and_return(mock)
          expect(mock).to receive(:deliver)
          user.send_reset_password_instructions
        end

        context 'when user is unconfirmed' do
          let(:user) { FactoryGirl.create("#{orm.underscore}_unconfirmed_user") }

          it 'returns false' do
            expect(user.send_reset_password_instructions).to be_falsey
          end

          it 'does not fill reset password fields' do
            user.send_reset_password_instructions
            user.reload
            expect(user.reset_password_token).to be_nil
            expect(user.reset_password_sent_at).to be_nil
          end

          it 'doe not send reset password email' do
            expect(RailsJwtAuth::Mailer).not_to receive(:reset_password_instructions)
            user.send_reset_password_instructions
          end
        end
      end

      describe '#before_save' do
        context 'when updates password' do
          it 'cleans reset password token' do
            user.reset_password_token = 'abcd'
            user.reset_password_sent_at = Time.now
            user.save
            expect(user.reload.reset_password_token).not_to be_nil

            user.password = 'newpassword'
            user.save
            expect(user.reload.reset_password_token).to be_nil
          end
        end
      end
    end
  end
end