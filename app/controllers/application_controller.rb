# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  private

  def set_paper_trail_whodunnit
    PaperTrail.request.whodunnit = current_user&.id if current_user
  end

  def after_sign_in_path_for(resource)
    root_path
  end
end