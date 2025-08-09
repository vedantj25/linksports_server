module Admin
  class LikesController < ApplicationController
    def index
      likes = Like.all
      sort = params[:sort].presence_in(%w[id created_at]) || "created_at"
      dir = params[:dir].presence_in(%w[asc desc]) || "desc"
      @likes = likes.order("#{sort} #{dir}").page(params[:page]).per(50)
    end

    def destroy
      like = Like.find(params[:id])
      like.destroy!
      AuditLog.create!(admin_user: current_user, action: "destroy_like", record_type: "Like", record_id: like.id, changeset: {})
      redirect_to admin_likes_path, notice: "Like removed."
    end
  end
end
