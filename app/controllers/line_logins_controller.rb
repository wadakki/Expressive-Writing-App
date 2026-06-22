class LineLoginsController < ApplicationController
  include LineOauth

  def new
    if logged_in?
      redirect_to root_path
      return
    end

    begin_line_oauth(flow: LineOauthSession::LOGIN_FLOW)
  rescue LineLoginClient::ConfigurationError => error
    line_oauth_session.clear
    log_line_login_error(error)
    redirect_to login_path, alert: t(".configuration_error")
  end
end
