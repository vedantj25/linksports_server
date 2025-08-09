module Admin
  class DashboardController < ApplicationController
    def index
      # Date range
      @start_date = params[:start_date].present? ? (Date.parse(params[:start_date]) rescue nil) : nil
      @end_date = params[:end_date].present? ? (Date.parse(params[:end_date]) rescue nil) : nil
      unless @start_date && @end_date && @start_date <= @end_date
        @end_date = Date.current
        @start_date = (@end_date - 6.days)
      end

      range = @start_date.beginning_of_day..@end_date.end_of_day

      @total_users = User.count
      @active_users = User.where(active: true).count
      @new_users_7d = User.where(created_at: (Date.current - 6.days).beginning_of_day..Date.current.end_of_day).count
      @profiles_by_type = Profile.group(:type).count
      @posts_7d = Post.where(created_at: (Date.current - 6.days).beginning_of_day..Date.current.end_of_day).count
      @comments_7d = Comment.where(created_at: (Date.current - 6.days).beginning_of_day..Date.current.end_of_day).count

      # Chart data for selected range
      days = (@start_date..@end_date).to_a
      @users_by_day = days.map { |day| [ day, User.where(created_at: day.all_day).count ] }
      @posts_by_day = days.map { |day| [ day, Post.where(created_at: day.all_day).count ] }
      @top_sports = Sport.joins(:posts).where(posts: { created_at: range }).group("sports.name").order(Arel.sql("COUNT(posts.id) DESC")).limit(5).count
    end
  end
end
