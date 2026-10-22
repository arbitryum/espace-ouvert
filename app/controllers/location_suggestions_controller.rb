class LocationSuggestionsController < ApplicationController
  def index
    query = params[:q].to_s.strip
    results = (query.length < 2) ? [] : Places.suggest(query)
    render json: {results:}
  end
end
