module Admin
  class DashboardController < ApplicationController
    def index
      @total_users = User.count
      @active_users = User.where(active: true).count
      @new_users_7d = User.where("created_at >= ?", 7.days.ago).count
      @profiles_by_type = Profile.group(:type).count
      @posts_7d = Post.where("created_at >= ?", 7.days.ago).count
      @comments_7d = Comment.where("created_at >= ?", 7.days.ago).count
    end
  end
end


