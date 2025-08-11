class Api::V1::UserSportAffiliationsController < Api::V1::BaseController
  before_action :set_user_sport
  before_action :set_affiliation, only: [ :update, :destroy ]

  # GET /api/v1/user_sports/:user_sport_id/affiliations
  def index
    render_success({ affiliations: @user_sport.user_sport_affiliations.order(created_at: :desc).map { |a| serialize(a) } })
  end

  # POST /api/v1/user_sports/:user_sport_id/affiliations
  def create
    a = @user_sport.user_sport_affiliations.create!(affiliation_params)
    render_success({ affiliation: serialize(a) }, "Affiliation added")
  end

  # PATCH /api/v1/user_sports/:user_sport_id/affiliations/:id
  def update
    @affiliation.update!(affiliation_params)
    render_success({ affiliation: serialize(@affiliation) }, "Affiliation updated")
  end

  # DELETE /api/v1/user_sports/:user_sport_id/affiliations/:id
  def destroy
    @affiliation.destroy!
    render_success({}, "Affiliation removed")
  end

  private

  def set_user_sport
    @user_sport = current_user.user_sports.find(params[:user_sport_id])
  end

  def set_affiliation
    @affiliation = @user_sport.user_sport_affiliations.find(params[:id])
  end

  def affiliation_params
    params.require(:affiliation).permit(:club_team_name, :league_competition, :start_month, :start_year, :end_month, :end_year, :current, :description)
  end

  def serialize(a)
    {
      id: a.id,
      club_team_name: a.club_team_name,
      league_competition: a.league_competition,
      start_month: a.start_month,
      start_year: a.start_year,
      end_month: a.end_month,
      end_year: a.end_year,
      current: a.current,
      description: a.description,
      pretty_duration: a.pretty_duration
    }
  end
end


