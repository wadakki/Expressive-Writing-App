class WritingEntriesController < ApplicationController
  before_action :require_login
  before_action :set_writing_entry, only: %i[show edit update]

  def index
    @writing_entries = current_user.writing_entries.completed.order(created_at: :desc)
  end

  def show; end

  def new
    @writing_entry = current_user.writing_entries.build
  end

  def edit; end

  def create
    @writing_entry = current_user.writing_entries.build(writing_entry_params)

    if @writing_entry.save
      redirect_to root_path, notice: t(".#{@writing_entry.status}_success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @writing_entry.update(writing_entry_params.except(:status))
      redirect_to @writing_entry, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_writing_entry
    @writing_entry = current_user.writing_entries.completed.find(params[:id])
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
      :status
    )
  end
end
