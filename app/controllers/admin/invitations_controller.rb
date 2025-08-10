module Admin
  class InvitationsController < ApplicationController
    skip_before_action :require_admin!, only: [ :accept ]
    before_action :authenticate_user!, only: [ :accept ]

    def index
      @invitations = AdminInvitation.order(created_at: :desc).page(params[:page]).per(25)
    end

    def new
      @invitation = AdminInvitation.new
    end

    def create
      @invitation = AdminInvitation.new(invitation_params.merge(invited_by: current_user))
      if @invitation.save
        AdminInvitationMailer.with(invitation: @invitation).invite_email.deliver_later
        redirect_to admin_invitations_path, notice: "Invitation created and email sent."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def accept
      token = params[:token].to_s
      invitation = AdminInvitation.active.find_by!(token: token)
      current_user.update!(role: invitation.role)
      invitation.update!(accepted_at: Time.current)
      redirect_to admin_dashboard_path, notice: "Admin access granted."
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: "Invalid or expired invitation."
    end

    private

    def invitation_params
      params.require(:admin_invitation).permit(:email, :role)
    end
  end
end
