class Coworking::ProjectsController < ApplicationController
  def index
    @projects = CoworkingProject.visible.includes(care_home: :address_details)
    @view_mode = (params[:view_mode] == "map") ? "map" : "list"
  end
end
