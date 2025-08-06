class Api::V1::SportsController < Api::V1::BaseController
  skip_before_action :authenticate_with_jwt!, only: [ :index, :show ]

  # GET /api/v1/sports
  def index
    sports = Sport.active.order(:name)

    if params[:category].present?
      sports = sports.by_category(params[:category])
    end

    if params[:q].present?
      sports = sports.where("name ILIKE ?", "%#{params[:q]}%")
    end

    render_success({
      sports: sports.map { |sport| sport_data(sport) },
      categories: Sport.active.distinct.pluck(:category).compact.sort
    })
  end

  # GET /api/v1/sports/:id
  def show
    sport = Sport.active.find(params[:id])
    render_success({ sport: sport_data_detailed(sport) })
  end

  # GET /api/v1/sports/categories
  def categories
    categories = Sport.active.distinct.pluck(:category).compact.sort
    render_success({ categories: categories })
  end

  private

  def sport_data(sport)
    {
      id: sport.id,
      name: sport.name,
      category: sport.category,
      active: sport.active
    }
  end

  def sport_data_detailed(sport)
    sport_data(sport).merge({
      users_count: sport.users.active.verified.count,
      recent_players: sport.users.joins(:profile)
                          .where(user_type: "player", verified: true, active: true)
                          .includes(:profile)
                          .limit(5)
                          .map { |user|
                            {
                              id: user.id,
                              display_name: user.display_name,
                              profile_id: user.profile.id,
                              location: [ user.profile.location_city, user.profile.location_state ].compact.join(", ")
                            }
                          }
    })
  end
end
