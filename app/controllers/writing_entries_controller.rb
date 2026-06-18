class WritingEntriesController < ApplicationController
  before_action :require_login
  before_action :set_completed_writing_entry, only: :show
  before_action :set_writing_entry, only: %i[edit update destroy]

  def index
    @writing_entries = current_user_writing_entries.order(created_at: :desc)
  end

  def show; end

  def new
    @writing_entry = current_user.writing_entries.build
  end

  def edit; end

  def create
    @writing_entry = current_user_writing_entries.build(writing_entry_params)

    if @writing_entry.save
      redirect_to root_path, notice: t(".#{@writing_entry.status}_success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @writing_entry.update(update_writing_entry_params)
      redirect_to after_update_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @writing_entry.destroy!
    redirect_to writing_entries_path, notice: t(".success"), status: :see_other
  end

  private

  def current_user_writing_entries
    current_user.writing_entries
  end

  def set_completed_writing_entry
    @writing_entry = current_user_writing_entries.completed.find(params[:id])
  end

  def set_writing_entry
    @writing_entry = current_user_writing_entries.find(params[:id])
  end

  def writing_entry_params
    params.require(:writing_entry).permit(
      :before_happiness_score,
      :after_happiness_score,
      :event_detail,
      :negative_emotion_detail,
      :positive_emotion_detail,
      :unforgiven_target_detail,
      :tomorrow_hope,
      :timer_remaining_seconds,
      :status
    )
  end

  def update_writing_entry_params
    if @writing_entry.draft?
      writing_entry_params
    else
      writing_entry_params.except(:status)
    end
  end

  def after_update_path
    if @writing_entry.completed?
      @writing_entry
    else
      writing_entries_path
    end
  end
end
