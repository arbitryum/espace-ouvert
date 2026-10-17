class SpacesController < ApplicationController
  def index
    @search = SpaceSearch.new(params.permit(:care_home, :location, :near_lat, :near_lon, :near_mode, :radius_km))
    @spaces = @search.results
    flash.now[:alert] = @search.warning if @search.warning
    @view_mode = params[:view_mode] == "map" ? "map" : "list"
    @care_home_options = CareHome.where(id: Space.listed.select(:care_home_id)).order(:name)
  end

  def show
    @space = Space.already_published.includes(:recurring_availabilities, care_home: :address_details).find(params[:id])
    @images = @space.images.with_attached_image
  end
end
