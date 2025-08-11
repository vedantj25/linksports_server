class Api::V1::UserSportTournamentsController < Api::V1::BaseController
  before_action :set_user_sport
  before_action :set_tournament, only: [ :update, :destroy ]

  # GET /api/v1/user_sports/:user_sport_id/tournaments
  def index
    render_success({ tournaments: @user_sport.user_sport_tournaments.order(year: :desc).map { |t| serialize(t) } })
  end

  # POST /api/v1/user_sports/:user_sport_id/tournaments
  def create
    t = @user_sport.user_sport_tournaments.create!(tournament_params)
    render_success({ tournament: serialize(t) }, "Tournament added")
  end

  # PATCH /api/v1/user_sports/:user_sport_id/tournaments/:id
  def update
    @tournament.update!(tournament_params)
    render_success({ tournament: serialize(@tournament) }, "Tournament updated")
  end

  # DELETE /api/v1/user_sports/:user_sport_id/tournaments/:id
  def destroy
    @tournament.destroy!
    render_success({}, "Tournament removed")
  end

  private

  def set_user_sport
    @user_sport = current_user.user_sports.find(params[:user_sport_id])
  end

  def set_tournament
    @tournament = @user_sport.user_sport_tournaments.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(:tournament_name, :year, :description)
  end

  def serialize(t)
    {
      id: t.id,
      tournament_name: t.tournament_name,
      year: t.year,
      description: t.description
    }
  end
end


