module Admin
  class UserSportTournamentsController < ApplicationController
    before_action :set_user_sport
    before_action :set_tournament, only: [ :show, :edit, :update, :destroy ]

    def index
      @tournaments = @user_sport.user_sport_tournaments.order(year: :desc, tournament_name: :asc)
    end

    def new
      @tournament = @user_sport.user_sport_tournaments.new
    end

    def create
      @tournament = @user_sport.user_sport_tournaments.new(tournament_params)
      if @tournament.save
        AuditLog.create!(admin_user: current_user, action: "create_user_sport_tournament", record_type: "UserSportTournament", record_id: @tournament.id, changeset: @tournament.previous_changes.except(:updated_at))
        redirect_to admin_user_user_sport_tournaments_path(@user_sport.user, @user_sport), notice: "Tournament added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @tournament.update(tournament_params)
        AuditLog.create!(admin_user: current_user, action: "update_user_sport_tournament", record_type: "UserSportTournament", record_id: @tournament.id, changeset: @tournament.previous_changes.except(:updated_at))
        redirect_to admin_user_user_sport_tournaments_path(@user_sport.user, @user_sport), notice: "Tournament updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tournament.destroy!
      AuditLog.create!(admin_user: current_user, action: "destroy_user_sport_tournament", record_type: "UserSportTournament", record_id: @tournament.id, changeset: {})
      redirect_to admin_user_user_sport_tournaments_path(@user_sport.user, @user_sport), notice: "Tournament removed."
    end

    private

    def set_user_sport
      @user = User.find(params[:user_id])
      @user_sport = @user.user_sports.find(params[:user_sport_id])
    end

    def set_tournament
      @tournament = @user_sport.user_sport_tournaments.find(params[:id])
    end

    def tournament_params
      params.require(:user_sport_tournament).permit(:tournament_name, :year, :description)
    end
  end
end
