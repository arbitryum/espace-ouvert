module Madmin
  class ApplicationController < Madmin::BaseController
    include ::Authentication

    before_action :require_admin

    private

    def require_admin
      redirect_to main_app.root_path, alert: "Accès réservé aux administrateurs." unless Current.user&.admin?
    end

    def new_session_path = main_app.new_session_path
    def root_url = main_app.root_url
  end
end
