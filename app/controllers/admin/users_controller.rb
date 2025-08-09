module Admin
  class UsersController < ApplicationController
    before_action :set_user, only: [
      :show, :edit, :update,
      :activate, :deactivate, :ban, :unban,
      :soft_delete, :restore, :verify_email, :verify_phone,
      :reset_password, :force_logout
    ]

    def index
      @q = params[:q].to_s.strip
      users = User.all
      case params[:status]
      when "active" then users = users.where(active: true)
      when "inactive" then users = users.where(active: false)
      when "banned" then users = users.where(banned: true)
      when "admin" then users = users.where(role: :admin)
      end
      if @q.present?
        users = users.where("LOWER(email) LIKE :q OR LOWER(username) LIKE :q OR LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q", q: "%#{@q.downcase}%")
      end
      sort = params[:sort].presence_in(%w[id first_name username email active created_at]) || "created_at"
      dir = params[:dir].presence_in(%w[asc desc]) || "desc"
      @users = users.order("#{sort} #{dir}").page(params[:page]).per(25)
    end

    def search
      redirect_to admin_users_path(q: params[:q])
    end

    def show; end

    def edit; end

    def update
      permitted = params.require(:user).permit(:first_name, :last_name, :email, :phone, :username, :active, :role)
      if @user.update(permitted)
        log_admin_action!(action: "update_user", record: @user)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def activate
      @user.update!(active: true)
      log_admin_action!(action: "activate_user", record: @user)
      redirect_to admin_user_path(@user), notice: "User activated."
    end

    def deactivate
      reason = params[:reason].to_s
      @user.update!(active: false)
      log_admin_action!(action: "deactivate_user", record: @user, reason: reason)
      redirect_to admin_user_path(@user), notice: "User deactivated."
    end

    def ban
      reason = params[:reason].to_s
      @user.update!(banned: true, banned_reason: reason, banned_at: Time.current)
      log_admin_action!(action: "ban_user", record: @user, reason: reason)
      redirect_to admin_user_path(@user), notice: "User banned."
    end

    def unban
      @user.update!(banned: false, banned_reason: nil, banned_at: nil)
      log_admin_action!(action: "unban_user", record: @user)
      redirect_to admin_user_path(@user), notice: "User unbanned."
    end

    def soft_delete
      reason = params[:reason].to_s
      @user.update!(deleted_at: Time.current)
      log_admin_action!(action: "soft_delete_user", record: @user, reason: reason)
      redirect_to admin_user_path(@user), notice: "User soft-deleted."
    end

    def restore
      @user.update!(deleted_at: nil)
      log_admin_action!(action: "restore_user", record: @user)
      redirect_to admin_user_path(@user), notice: "User restored."
    end

    def verify_email
      contact = @user.email_contact || @user.user_contacts.create!(contact_type: :email, value: @user.email)
      contact.update!(verified: true)
      log_admin_action!(action: "verify_email", record: contact)
      redirect_to admin_user_path(@user), notice: "Email marked verified."
    end

    def verify_phone
      contact = @user.phone_contact || @user.user_contacts.create!(contact_type: :phone, value: @user.phone)
      contact.update!(verified: true)
      log_admin_action!(action: "verify_phone", record: contact)
      redirect_to admin_user_path(@user), notice: "Phone marked verified."
    end

    def reset_password
      @user.send_reset_password_instructions
      log_admin_action!(action: "reset_password_instructions", record: @user)
      redirect_to admin_user_path(@user), notice: "Password reset instructions sent."
    end

    def force_logout
      # Invalidate all sessions by rotating Devise remember token & (if using JWT later, revoke)
      @user.update!(remember_created_at: Time.current)
      log_admin_action!(action: "force_logout", record: @user)
      redirect_to admin_user_path(@user), notice: "User will be logged out from all sessions."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def log_admin_action!(action:, record:, reason: nil)
      AuditLog.create!(
        admin_user: current_user,
        action: action,
        record_type: record.class.name,
        record_id: record.id,
        reason: reason,
        changeset: record.previous_changes.except(:updated_at)
      )
    end
  end
end
