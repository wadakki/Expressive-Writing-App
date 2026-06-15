class StaticPagesController < ApplicationController
  def home
    redirect_to writing_entries_path if logged_in?
  end

  def terms; end
  def privacy; end
  def contact; end
end
