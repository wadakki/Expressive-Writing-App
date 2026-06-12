class UserSessionsController < ApplicationController
  def new; end

  def create
    @user = login(user_session_params[:email], user_session_params[:password])

    if @user
      redirect_to root_path, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: t(".success")
  end

  private

  def user_session_params
    params.require(:user_session).permit(
      :email,
      :password
    )
  end
end
