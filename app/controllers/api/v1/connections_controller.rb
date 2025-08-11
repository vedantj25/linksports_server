class Api::V1::ConnectionsController < Api::V1::BaseController
  before_action :set_connection, only: [ :update, :destroy ]

  # GET /api/v1/connections
  def index
    connections = Connection
      .where("requester_id = :id OR addressee_id = :id", id: current_user.id)
      .where(status: :accepted)
      .includes(:requester, :addressee)

    render_success({ connections: connections.map { |c| connection_data(c) } })
  end

  # GET /api/v1/connections/requests
  def requests
    pending = Connection.where(addressee_id: current_user.id, status: :pending).includes(:requester)
    render_success({ requests: pending.map { |c| connection_data(c) } })
  end

  # POST /api/v1/connections
  # Params: addressee_id
  def create
    addressee = User.find(params[:addressee_id])
    if addressee.id == current_user.id
      return render_error("cannot connect to self", :unprocessable_entity)
    end

    connection = Connection.between_users(current_user, addressee)
    if connection
      return render_success({ connection: connection_data(connection) }, "Already exists")
    end

    connection = Connection.create!(requester: current_user, addressee: addressee, status: :pending)
    render_success({ connection: connection_data(connection) }, "Request sent")
  end

  # PATCH /api/v1/connections/:id
  # Params: status = accepted | blocked | pending
  def update
    unless @connection.addressee_id == current_user.id || @connection.requester_id == current_user.id
      return render_error("Not allowed", :forbidden)
    end

    new_status = params[:status].to_s
    unless Connection.statuses.key?(new_status)
      return render_error("Invalid status", :unprocessable_entity)
    end

    @connection.update!(status: new_status)
    if @connection.accepted?
      @connection.update!(connected_at: Time.current)
    end
    render_success({ connection: connection_data(@connection) }, "Updated")
  end

  # DELETE /api/v1/connections/:id
  def destroy
    unless @connection.addressee_id == current_user.id || @connection.requester_id == current_user.id
      return render_error("Not allowed", :forbidden)
    end
    @connection.destroy
    render_success({}, "Deleted")
  end

  private

  def set_connection
    @connection = Connection.find(params[:id])
  end

  def connection_data(conn)
    {
      id: conn.id,
      status: conn.status,
      connected_at: conn.connected_at,
      requester: {
        id: conn.requester.id,
        username: conn.requester.username,
        display_name: conn.requester.display_name
      },
      addressee: {
        id: conn.addressee.id,
        username: conn.addressee.username,
        display_name: conn.addressee.display_name
      }
    }
  end
end


