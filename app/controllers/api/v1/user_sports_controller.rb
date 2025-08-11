class Api::V1::UserSportsController < Api::V1::BaseController
  before_action :set_user_sport, only: [ :update, :destroy ]

  # GET /api/v1/user_sports
  def index
    user_sports = current_user.user_sports.includes(:sport, :user_sport_affiliations, :user_sport_tournaments)
    render_success({ user_sports: user_sports.map { |us| serialize_user_sport(us) } })
  end

  # POST /api/v1/user_sports
  def create
    us = current_user.user_sports.create!(user_sport_params)
    upsert_nested(us)
    render_success({ user_sport: serialize_user_sport(us.reload) }, "User sport created")
  end

  # PATCH/PUT /api/v1/user_sports/:id
  def update
    @user_sport.update!(user_sport_params)
    upsert_nested(@user_sport)
    render_success({ user_sport: serialize_user_sport(@user_sport.reload) }, "User sport updated")
  end

  # DELETE /api/v1/user_sports/:id
  def destroy
    @user_sport.destroy!
    render_success({}, "User sport deleted")
  end

  private

  def set_user_sport
    @user_sport = current_user.user_sports.find(params[:id])
  end

  def user_sport_params
    params.require(:user_sport).permit(:sport_id, :position, :years_experience, :primary, details: {})
  end

  def upsert_nested(user_sport)
    # Optional nested create for affiliations and tournaments arrays
    if params[:affiliations].present?
      user_sport.user_sport_affiliations.destroy_all
      Array(params[:affiliations]).each do |aff|
        next unless aff.is_a?(Hash) || aff.is_a?(ActionController::Parameters)
        h = aff.is_a?(ActionController::Parameters) ? aff.to_unsafe_h : aff
        user_sport.user_sport_affiliations.create!(
          club_team_name: h["club_team_name"],
          league_competition: h["league_competition"],
          start_month: h["start_month"],
          start_year: h["start_year"],
          end_month: h["end_month"],
          end_year: h["end_year"],
          current: h["current"],
          description: h["description"]
        )
      end
    end

    if params[:tournaments].present?
      user_sport.user_sport_tournaments.destroy_all
      Array(params[:tournaments]).each do |t|
        next unless t.is_a?(Hash) || t.is_a?(ActionController::Parameters)
        h = t.is_a?(ActionController::Parameters) ? t.to_unsafe_h : t
        user_sport.user_sport_tournaments.create!(
          tournament_name: h["tournament_name"],
          year: h["year"],
          description: h["description"]
        )
      end
    end
  end

  def serialize_user_sport(us)
    {
      id: us.id,
      sport: { id: us.sport.id, name: us.sport.name, category: us.sport.category },
      position: us.position,
      years_experience: us.years_experience,
      primary: us.primary,
      details: us.details || {},
      affiliations: us.user_sport_affiliations.order(created_at: :desc).map do |aff|
        {
          id: aff.id,
          club_team_name: aff.club_team_name,
          league_competition: aff.league_competition,
          start_month: aff.start_month,
          start_year: aff.start_year,
          end_month: aff.end_month,
          end_year: aff.end_year,
          current: aff.current,
          description: aff.description,
          pretty_duration: aff.pretty_duration
        }
      end,
      tournaments: us.user_sport_tournaments.order(year: :desc).map do |t|
        { id: t.id, tournament_name: t.tournament_name, year: t.year, description: t.description }
      end
    }
  end
end


