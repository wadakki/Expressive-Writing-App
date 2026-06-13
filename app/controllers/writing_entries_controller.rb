class WritingEntriesController < ApplicationController
  before_action :require_login

  def new
    @writing_entry = current_user.writing_entries.build
  end
end
