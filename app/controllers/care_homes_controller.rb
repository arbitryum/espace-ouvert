class CareHomesController < ApplicationController
  def show
    @care_home = CareHome.includes(:address_details).find(params.expect(:id))
    @spaces = @care_home.spaces.listed.includes(:recurring_availabilities)
  end
end
