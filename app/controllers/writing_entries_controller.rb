class WritingEntriesController < ApplicationController
  before_action :require_login

  def new
    @writing_entry = current_user.writing_entries.build
  end

  def create
    @writing_entry = current_user.writing_entries.build(writing_entry_params)

    if @writing_entry.save
      redirect_to root_path, notice: t(".#{@writing_entry.status}_success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

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
