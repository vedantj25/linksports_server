module Admin
  class UserContactsController < ApplicationController
    def index
      @user_contacts = UserContact.order(created_at: :desc).page(params[:page]).per(50)
    end

    def update
      user_contact = UserContact.find(params[:id])
      user_contact.update!(verified: params[:verified])
      AuditLog.create!(admin_user: current_user, action: "update_user_contact", record_type: "UserContact", record_id: user_contact.id, changeset: user_contact.previous_changes.except(:updated_at))
      redirect_to admin_user_contacts_path, notice: "Contact updated."
    end
  end
end
