module Admin
  class ConnectionsController < ApplicationController
    def index
      @connections = Connection.order(created_at: :desc).page(params[:page]).per(50)
    end

    def destroy
      connection = Connection.find(params[:id])
      connection.destroy!
      AuditLog.create!(admin_user: current_user, action: "destroy_connection", record_type: "Connection", record_id: connection.id, changeset: {})
      redirect_to admin_connections_path, notice: "Connection removed."
    end
  end
end
