module Admin
  class PostsController < ApplicationController
    before_action :set_post, only: [ :show, :update, :destroy, :hide, :unhide, :soft_delete, :restore, :disable_comments, :enable_comments ]

    def index
      posts = Post.order(created_at: :desc)
      if params[:vis].present? && Post.visibilities.key?(params[:vis])
        posts = posts.where(visibility: Post.visibilities[params[:vis]])
      end
      if params[:q].present?
        q = "%#{params[:q].downcase}%"
        posts = posts.where("LOWER(content) LIKE ?", q)
      end
      sort = params[:sort].presence_in(%w[id visibility created_at]) || 'created_at'
      dir = params[:dir].presence_in(%w[asc desc]) || 'desc'
      @posts = posts.order("#{sort} #{dir}").page(params[:page]).per(25)
    end

    def show; end

    def update
      permitted = params.require(:post).permit(:content, :visibility)
      if @post.update(permitted)
        log_admin_action!(action: "update_post", record: @post)
        redirect_to admin_post_path(@post), notice: "Post updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy!
      log_admin_action!(action: "destroy_post", record: @post)
      redirect_to admin_posts_path, notice: "Post deleted."
    end

    def hide
      @post.update!(visibility: :private_post)
      log_admin_action!(action: "hide_post", record: @post)
      redirect_to admin_post_path(@post), notice: "Post hidden."
    end

    def unhide
      @post.update!(visibility: :public_post)
      log_admin_action!(action: "unhide_post", record: @post)
      redirect_to admin_post_path(@post), notice: "Post visible."
    end

    def soft_delete
      @post.update!(deleted_at: Time.current)
      log_admin_action!(action: "soft_delete_post", record: @post)
      redirect_to admin_post_path(@post), notice: "Post soft-deleted."
    end

    def restore
      @post.update!(deleted_at: nil)
      log_admin_action!(action: "restore_post", record: @post)
      redirect_to admin_post_path(@post), notice: "Post restored."
    end

    def disable_comments
      @post.update!(comments_enabled: false)
      log_admin_action!(action: "disable_post_comments", record: @post)
      redirect_to admin_post_path(@post), notice: "Comments disabled."
    end

    def enable_comments
      @post.update!(comments_enabled: true)
      log_admin_action!(action: "enable_post_comments", record: @post)
      redirect_to admin_post_path(@post), notice: "Comments enabled."
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def log_admin_action!(action:, record:, reason: nil)
      AuditLog.create!(
        admin_user: current_user,
        action: action,
        record_type: record.class.name,
        record_id: record.id,
        reason: reason,
        changeset: record.previous_changes.except(:updated_at)
      )
    end
  end
end
