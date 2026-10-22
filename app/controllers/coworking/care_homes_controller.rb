# The coworking directory: care homes that can host a small team.
class Coworking::CareHomesController < ApplicationController
  def index
    @care_homes = CareHome.in_coworking_directory.includes(:address_details, :hosting_requests, coworking_photos_attachments: :blob)
    @view_mode = (params[:view_mode] == "map") ? "map" : "list"
  end
end
