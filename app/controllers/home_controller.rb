class HomeController < ApplicationController
  def index
    if user_signed_in?
      # Dashboard data for authenticated users
      @user_profile = current_user.profile
      @recent_profiles = Profile.completed.where.not(user: current_user).limit(6)
      @user_sports = current_user.sports
      @total_users = User.active.count
      @total_sports = Sport.active.count
      # Feed posts: public posts, connections' posts (public or connections-only), and own posts
      connected_ids = current_user.connected_user_ids
      @feed_posts = Post
                     .by_recent
                     .includes(user: :profile)
                     .where(
                       "(visibility = :public_vis) OR (user_id IN (:ids) AND visibility IN (:conn_vis)) OR (user_id = :me)",
                       public_vis: Post.visibilities[:public_post],
                       ids: connected_ids.presence || [ -1 ],
                       conn_vis: [ Post.visibilities[:public_post], Post.visibilities[:connections_only] ],
                       me: current_user.id
                     )
                     .limit(25)
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
