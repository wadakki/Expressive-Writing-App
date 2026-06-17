class ProfilesController < ApplicationController
  before_action :require_login
  before_action :set_user

  def show; end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: t(".success")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
