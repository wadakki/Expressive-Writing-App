module LineOauth
  private

  def begin_line_oauth(flow:, bot_prompt: nil)
    oauth = line_oauth_session.start(flow:)
    authorization_url = line_login_client.authorization_url(
      state: oauth[:state],
      nonce: oauth[:nonce],
      bot_prompt:
    )

    redirect_to authorization_url, allow_other_host: true
  end

  def line_oauth_session
    @line_oauth_session ||= LineOauthSession.new(session:)
  end

  def line_login_client
    @line_login_client ||= LineLoginClient.new
  end

  def log_line_login_error(error)
    Rails.logger.error("LINE Login error: #{error.class}")
  end
end
