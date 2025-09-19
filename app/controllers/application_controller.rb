# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  private

  def after_sign_in_path_for(resource)
    root_path
  end
end