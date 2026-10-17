class Coworking::ProjectsController < ApplicationController
  def index
    @projects = CoworkingProject.visible.includes(:care_home)
  end
end
