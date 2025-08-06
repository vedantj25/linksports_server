class HomeController < ApplicationController
  def index
    if user_signed_in?
      # Dashboard data for authenticated users
      @user_profile = current_user.profile
      @recent_profiles = Profile.completed.where.not(user: current_user).limit(6)
      @user_sports = current_user.sports
      @total_users = User.active.count
      @total_sports = Sport.active.count
      render "dashboard"
    else
      # Landing page data for visitors
      @featured_sports = Sport.active.limit(8)
      @total_users = User.active.count
      @total_sports = Sport.active.count
      @total_connections = 0 # Will be updated when we have connections
      render "index"
    end
  end

  def about
  end

  def contact
  end

  def privacy
  end

  def terms
  end

  def discover
    @featured_profiles = Profile.completed.limit(12) # Show featured profiles
  end

  def events
    # Future: Add events model and fetch upcoming events
    @upcoming_events = []
  end
end
