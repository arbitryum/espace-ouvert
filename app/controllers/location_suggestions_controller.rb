class LocationSuggestionsController < ApplicationController
  def index
    query = params[:q].to_s.strip
    results = (query.length < 2) ? [] : Geocoder.suggest(query)
    render json: {results:}
  end
end
