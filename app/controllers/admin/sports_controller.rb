module Admin
  class SportsController < ApplicationController
    before_action :set_sport, only: [ :show, :edit, :update, :destroy ]

    def index
      @sports = Sport.order(:name).page(params[:page]).per(50)
    end

    def show; end

    def new
      @sport = Sport.new
    end

    def create
      @sport = Sport.new(sport_params)
      if @sport.save
        AuditLog.create!(admin_user: current_user, action: "create_sport", record_type: "Sport", record_id: @sport.id, changeset: @sport.previous_changes.except(:updated_at))
        redirect_to admin_sport_path(@sport), notice: "Sport created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @sport.update(sport_params)
        AuditLog.create!(admin_user: current_user, action: "update_sport", record_type: "Sport", record_id: @sport.id, changeset: @sport.previous_changes.except(:updated_at))
        redirect_to admin_sport_path(@sport), notice: "Sport updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @sport.destroy!
      AuditLog.create!(admin_user: current_user, action: "destroy_sport", record_type: "Sport", record_id: @sport.id, changeset: {})
      redirect_to admin_sports_path, notice: "Sport deleted."
    end

    private

    def set_sport
      @sport = Sport.find(params[:id])
    end

    def sport_params
      params.require(:sport).permit(:name, :category, :active)
    end
  end
end
