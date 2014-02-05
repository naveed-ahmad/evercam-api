module Evercam
  module Mailers
    class AccountMailer < Mailer

      def password_reset
        {
          to: user.email,
          subject: 'Evercam Password Reset Instructions',
          body: erb('account/password_reset.txt')
        }
      end

    end
  end
end

