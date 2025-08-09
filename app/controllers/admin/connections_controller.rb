module Admin
  class ConnectionsController < ApplicationController
    def index
      connections = Connection.all
      sort = params[:sort].presence_in(%w[id status created_at]) || "created_at"
      dir = params[:dir].presence_in(%w[asc desc]) || "desc"
      @connections = connections.order("#{sort} #{dir}").page(params[:page]).per(50)
    end

    def destroy
      connection = Connection.find(params[:id])
      connection.destroy!
      AuditLog.create!(admin_user: current_user, action: "destroy_connection", record_type: "Connection", record_id: connection.id, changeset: {})
      redirect_to admin_connections_path, notice: "Connection removed."
    end
  end
end
