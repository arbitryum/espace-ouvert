class AddressSuggestionsController < ApplicationController
  def index
    render json: {results: Addresses.suggest(params.expect(:q))}
  end
end
