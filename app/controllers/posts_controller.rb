class PostsController < ApplicationController
  before_action :authenticate_user!

  def create
    post = current_user.posts.build(post_params)
    if post.save
      redirect_to root_path, notice: "Post created"
    else
      redirect_to root_path, alert: post.errors.full_messages.to_sentence
    end
  end

  private

  def post_params
    params.require(:post).permit(:content, :visibility, :sport_id)
  end
end
