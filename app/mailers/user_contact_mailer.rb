class UserContactMailer < ApplicationMailer
  def verification_code_email
    @contact = params[:contact]
    @user = @contact.user
    @code = @contact.verification_code
    mail(to: @contact.value, subject: "Your LinkSports verification code")
  end
end
