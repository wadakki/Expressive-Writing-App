class LineConnectionsController < ApplicationController
  include LineOauth

  before_action :require_login

  def new
    begin_line_oauth(flow: LineOauthSession::LINK_FLOW, bot_prompt: "aggressive")
  rescue LineLoginClient::ConfigurationError => error
    line_oauth_session.clear
    log_line_login_error(error)
    redirect_to profile_path, alert: t(".configuration_error")
  end

  def destroy
    ActiveRecord::Base.transaction do
      current_user.authentications.find_by(provider: "line")&.destroy!
      current_user.line_connection&.destroy!
    end

    redirect_to profile_path, notice: t(".destroy_success"), status: :see_other
  end
end
