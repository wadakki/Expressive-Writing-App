class LineOauthCallbacksController < ApplicationController
  include LineOauth

  def show
    @oauth_flow = line_oauth_session.flow
    oauth = line_oauth_session.consume!(state: params[:state])
    @oauth_flow = oauth[:flow]

    if params[:error].present?
      redirect_to oauth_redirect_path, alert: canceled_message
      return
    end

    line_user_id = line_login_client.user_id(code: params[:code], nonce: oauth[:nonce])
    line_login_flow? ? login_with_line!(line_user_id) : link_with_line!(line_user_id)
  rescue LineOauthSession::InvalidStateError
    redirect_to oauth_redirect_path, alert: t(".invalid_state")
  rescue LineLoginClient::ConfigurationError => error
    log_line_login_error(error)
    redirect_to oauth_redirect_path, alert: t(".configuration_error")
  rescue LineLoginClient::AuthenticationError => error
    log_line_login_error(error)
    redirect_to oauth_redirect_path, alert: t(".authentication_error")
  rescue LineAccountLinker::LinkingError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to profile_path, alert: t(".already_linked")
  end

  private

  def line_login_flow?
    @oauth_flow == LineOauthSession::LOGIN_FLOW
  end

  def link_with_line!(line_user_id)
    unless logged_in?
      redirect_to login_path, alert: t("application.authentication_required")
      return
    end

    LineAccountLinker.call(user: current_user, line_user_id:)
    redirect_to profile_path, notice: t(".link_success")
  end

  def login_with_line!(line_user_id)
    authentication = Authentication.includes(:user).find_by(
      provider: "line",
      uid: line_user_id
    )
    unless authentication
      redirect_to login_path, alert: t(".unlinked_account")
      return
    end

    user = authentication.user
    reset_session
    auto_login(user)
    redirect_to root_path, notice: t(".login_success")
  end

  def oauth_redirect_path
    if @oauth_flow == LineOauthSession::LINK_FLOW && logged_in?
      profile_path
    else
      login_path
    end
  end

  def canceled_message
    line_login_flow? ? t(".login_canceled") : t(".link_canceled")
  end
end
