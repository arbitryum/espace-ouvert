class HomeController < ApplicationController
  def index
    @care_home_count = CareHome.where(id: Space.open.select(:care_home_id)).count
  end
end
