module Admin
  class CommentsController < ApplicationController
    before_action :set_comment, only: [ :show, :destroy, :soft_delete, :restore ]

    def index
      comments = Comment.all
      sort = params[:sort].presence_in(%w[id created_at]) || "created_at"
      dir = params[:dir].presence_in(%w[asc desc]) || "desc"
      @comments = comments.order("#{sort} #{dir}").page(params[:page]).per(25)
    end

    def show; end

    def destroy
      @comment.destroy!
      log_admin_action!(action: "destroy_comment", record: @comment)
      redirect_to admin_comments_path, notice: "Comment deleted."
    end

    def soft_delete
      @comment.update!(deleted_at: Time.current)
      log_admin_action!(action: "soft_delete_comment", record: @comment)
      redirect_to admin_comment_path(@comment), notice: "Comment soft-deleted."
    end

    def restore
      @comment.update!(deleted_at: nil)
      log_admin_action!(action: "restore_comment", record: @comment)
      redirect_to admin_comment_path(@comment), notice: "Comment restored."
    end

    private

    def set_comment
      @comment = Comment.find(params[:id])
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
