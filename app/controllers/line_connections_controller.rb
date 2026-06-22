class LineConnectionsController < ApplicationController
  class LinkingError < StandardError; end

  before_action :require_login

  def new
    state = SecureRandom.urlsafe_base64(32)
    nonce = SecureRandom.urlsafe_base64(32)
    session[:line_login_state] = state
    session[:line_login_nonce] = nonce

    redirect_to line_login_client.authorization_url(state:, nonce:), allow_other_host: true
  rescue LineLoginClient::ConfigurationError => error
    clear_oauth_session
    log_line_login_error(error)
    redirect_to profile_path, alert: t(".configuration_error")
  end

  def callback
    if params[:error].present?
      clear_oauth_session
      redirect_to profile_path, alert: t(".canceled")
      return
    end

    expected_state = session.delete(:line_login_state)
    nonce = session.delete(:line_login_nonce)
    unless valid_state?(expected_state, params[:state])
      redirect_to profile_path, alert: t(".invalid_state")
      return
    end

    line_user_id = line_login_client.user_id(code: params[:code], nonce:)
    link_line_account!(line_user_id)
    redirect_to profile_path, notice: t(".success")
  rescue LineLoginClient::ConfigurationError => error
    log_line_login_error(error)
    redirect_to profile_path, alert: t(".configuration_error")
  rescue LineLoginClient::AuthenticationError => error
    log_line_login_error(error)
    redirect_to profile_path, alert: t(".authentication_error")
  rescue LinkingError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to profile_path, alert: t(".already_linked")
  end

  def destroy
    ActiveRecord::Base.transaction do
      current_user.authentications.find_by(provider: "line")&.destroy!
      current_user.line_connection&.destroy!
    end

    redirect_to profile_path, notice: t(".destroy_success"), status: :see_other
  end

  private

  def line_login_client
    @line_login_client ||= LineLoginClient.new
  end

  def valid_state?(expected_state, actual_state)
    expected = expected_state.to_s
    actual = actual_state.to_s
    expected.present? && expected.bytesize == actual.bytesize &&
      ActiveSupport::SecurityUtils.secure_compare(expected, actual)
  end

  def link_line_account!(line_user_id)
    ensure_line_account_available!(line_user_id)

    ActiveRecord::Base.transaction do
      authentication = current_user.authentications.find_or_initialize_by(provider: "line")
      ensure_same_identity!(authentication.uid, line_user_id) if authentication.persisted?
      authentication.update!(uid: line_user_id)

      line_connection = current_user.line_connection || current_user.build_line_connection
      ensure_same_identity!(line_connection.line_user_id, line_user_id) if line_connection.persisted?
      line_connection.update!(
        line_user_id:,
        status: :linked,
        linked_at: Time.current
      )
    end
  end

  def ensure_line_account_available!(line_user_id)
    authentication = Authentication.find_by(provider: "line", uid: line_user_id)
    connection = LineConnection.find_by(line_user_id:)
    owners = [ authentication&.user_id, connection&.user_id ].compact
    raise LinkingError if owners.any? { |user_id| user_id != current_user.id }
  end

  def ensure_same_identity!(current_uid, received_uid)
    raise LinkingError unless current_uid == received_uid
  end

  def clear_oauth_session
    session.delete(:line_login_state)
    session.delete(:line_login_nonce)
  end

  def log_line_login_error(error)
    Rails.logger.error("LINE Login error: #{error.class}")
  end
end
