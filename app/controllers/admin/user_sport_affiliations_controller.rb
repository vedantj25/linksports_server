module Admin
  class UserSportAffiliationsController < ApplicationController
    before_action :set_user_sport
    before_action :set_affiliation, only: [ :show, :edit, :update, :destroy ]

    def index
      @affiliations = @user_sport.user_sport_affiliations.order(current: :desc, start_year: :desc)
    end

    def new
      @affiliation = @user_sport.user_sport_affiliations.new
    end

    def create
      @affiliation = @user_sport.user_sport_affiliations.new(affiliation_params)
      if @affiliation.save
        AuditLog.create!(admin_user: current_user, action: "create_user_sport_affiliation", record_type: "UserSportAffiliation", record_id: @affiliation.id, changeset: @affiliation.previous_changes.except(:updated_at))
        redirect_to admin_user_user_sport_affiliations_path(@user_sport.user, @user_sport), notice: "Affiliation added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @affiliation.update(affiliation_params)
        AuditLog.create!(admin_user: current_user, action: "update_user_sport_affiliation", record_type: "UserSportAffiliation", record_id: @affiliation.id, changeset: @affiliation.previous_changes.except(:updated_at))
        redirect_to admin_user_user_sport_affiliations_path(@user_sport.user, @user_sport), notice: "Affiliation updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @affiliation.destroy!
      AuditLog.create!(admin_user: current_user, action: "destroy_user_sport_affiliation", record_type: "UserSportAffiliation", record_id: @affiliation.id, changeset: {})
      redirect_to admin_user_user_sport_affiliations_path(@user_sport.user, @user_sport), notice: "Affiliation removed."
    end

    private

    def set_user_sport
      @user = User.find(params[:user_id])
      @user_sport = @user.user_sports.find(params[:user_sport_id])
    end

    def set_affiliation
      @affiliation = @user_sport.user_sport_affiliations.find(params[:id])
    end

    def affiliation_params
      params.require(:user_sport_affiliation).permit(:club_team_name, :league_competition, :start_year, :start_month, :end_year, :end_month, :description, :current)
    end
  end
end
