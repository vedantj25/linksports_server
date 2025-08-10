module Admin
  class SportAttributesController < ApplicationController
    before_action :set_sport_attribute, only: [ :show, :edit, :update, :destroy ]
    before_action :normalize_options, only: [ :create, :update ]

    def index
      @sport_attributes = SportAttribute.order(:key).page(params[:page]).per(50)
    end

    def show; end

    def new
      @sport_attribute = SportAttribute.new
    end

    def create
      @sport_attribute = SportAttribute.new(sport_attribute_params)
      if @sport_attribute.save
        AuditLog.create!(admin_user: current_user, action: "create_sport_attribute", record_type: "SportAttribute", record_id: @sport_attribute.id, changeset: @sport_attribute.previous_changes.except(:updated_at))
        redirect_to admin_sport_attribute_path(@sport_attribute), notice: "Sport attribute created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @sport_attribute.update(sport_attribute_params)
        AuditLog.create!(admin_user: current_user, action: "update_sport_attribute", record_type: "SportAttribute", record_id: @sport_attribute.id, changeset: @sport_attribute.previous_changes.except(:updated_at))
        redirect_to admin_sport_attribute_path(@sport_attribute), notice: "Sport attribute updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @sport_attribute.destroy!
      AuditLog.create!(admin_user: current_user, action: "destroy_sport_attribute", record_type: "SportAttribute", record_id: @sport_attribute.id, changeset: {})
      redirect_to admin_sport_attributes_path, notice: "Sport attribute deleted."
    end

    private

    def set_sport_attribute
      @sport_attribute = SportAttribute.find(params[:id])
    end

    def sport_attribute_params
      params.require(:sport_attribute).permit(:key, :label, :field_type, :active, options: [])
    end

    def normalize_options
      sa = params[:sport_attribute]
      return unless sa
      if sa[:options_text].present?
        sa[:options] = sa[:options_text].to_s.split(/\r?\n|,/).map(&:strip).reject(&:blank?)
      end
    end
  end
end
