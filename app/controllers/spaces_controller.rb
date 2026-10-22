class SpacesController < ApplicationController
  def index
    @search = SpaceSearch.new(params.permit(:city, :location, :department, :near_lat, :near_lon, :near_mode, :radius_km, :weekday, :moment))
    @spaces = @search.results
    flash.now[:alert] = t(".#{@search.warning}") if @search.warning
    @view_mode = (params[:view_mode] == "map") ? "map" : "list"
    @city_options = Address.joins(:care_homes).where(care_homes: {id: Space.listed.select(:care_home_id)}).where.not(city: "").distinct.order(:city).pluck(:city)
    @documents = SharedDocument.visible
  end

  def show
    @space = Space.already_published.includes(:recurring_availabilities, care_home: :address_details).find(params[:id])
    @images = @space.images.with_attached_image
  end
end
