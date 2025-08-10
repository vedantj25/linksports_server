class AdminInvitationMailer < ApplicationMailer
  def invite_email
    @invitation = params[:invitation]
    @accept_url = accept_admin_invitations_url(token: @invitation.token)

    mail(to: @invitation.email, subject: "You're invited to be an admin on LinkSports")
  end
end
