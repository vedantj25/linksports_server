class Api::V1::PostsController < Api::V1::BaseController
  before_action :set_post, only: [ :show, :destroy, :like, :unlike, :upload_media ]

  # GET /api/v1/posts
  # Optional params: page, per_page
  def index
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? [ params[:per_page].to_i, 50 ].min : 20

    # Basic feed: public posts + connections' posts + own posts
    visible_user_ids = [ current_user.id ] + current_user.connected_user_ids

    posts = Post
      .where("visibility = :public OR user_id IN (:ids)", public: Post.visibilities[:public_post], ids: visible_user_ids)
      .by_recent
      .includes(:user, :sport)
      .offset((page - 1) * per_page)
      .limit(per_page)

    render_success({
      posts: posts.map { |p| post_data(p) },
      page: page,
      per_page: per_page
    })
  end

  # POST /api/v1/posts
  def create
    post = current_user.posts.build(post_params)
    if post.save
      attach_media(post)
      render_success({ post: post_data(post) }, "Post created")
    else
      render_error("Post creation failed", :unprocessable_entity, post.errors)
    end
  end

  # GET /api/v1/posts/:id
  def show
    unless can_view?(@post)
      return render_error("Not allowed", :forbidden)
    end
    render_success({ post: post_data(@post) })
  end

  # DELETE /api/v1/posts/:id
  def destroy
    unless @post.user_id == current_user.id
      return render_error("You can only delete your own post", :forbidden)
    end
    @post.destroy
    render_success({}, "Post deleted")
  end

  # POST /api/v1/posts/:id/like
  def like
    Like.find_or_create_by!(user: current_user, post: @post)
    render_success({ likes_count: @post.reload.likes_count }, "Liked")
  end

  # DELETE /api/v1/posts/:id/unlike
  def unlike
    if (like = Like.find_by(user: current_user, post: @post))
      like.destroy
    end
    render_success({ likes_count: @post.reload.likes_count }, "Unliked")
  end

  # POST /api/v1/posts/:id/upload_media
  def upload_media
    unless @post.user_id == current_user.id
      return render_error("You can only upload media for your own post", :forbidden)
    end

    if params[:media].blank?
      return render_error("No media provided", :bad_request)
    end

    Array(params[:media]).each do |file|
      @post.media.attach(file)
    end

    render_success({ media_urls: media_urls(@post) }, "Media uploaded")
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:content, :visibility, :sport_id, :link_url)
  end

  def attach_media(post)
    return if params[:media].blank?
    Array(params[:media]).each do |file|
      post.media.attach(file)
    end
  end

  def media_urls(post)
    post.media.map { |att| url_for(att) }
  end

  def can_view?(post)
    return true if post.public_post?
    return true if post.user_id == current_user.id
    return true if post.connections_only? && current_user.connected_with?(post.user)
    false
  end

  def post_data(post)
    {
      id: post.id,
      content: post.content,
      link_url: post.try(:link_url),
      visibility: post.visibility,
      created_at: post.created_at,
      updated_at: post.updated_at,
      likes_count: post.likes_count,
      comments_count: post.comments_count,
      user: {
        id: post.user.id,
        username: post.user.username,
        display_name: post.user.display_name
      },
      sport: post.sport && { id: post.sport.id, name: post.sport.name },
      media_urls: media_urls(post)
    }
  end
end


