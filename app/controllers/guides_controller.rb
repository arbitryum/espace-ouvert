class GuidesController < ApplicationController
  include GuideAccess

  # The guide's sections, as boxes. Without access, ?page= opens the email form
  # for that page.
  def index
    @sections = GuidePage.sections
    @requested_page = GuidePage.find_by(slug: params[:page]) unless guide_access?
  end

  def show
    return redirect_to guide_path(page: params[:slug]) unless guide_access?

    @page = GuidePage.find_by!(slug: params[:slug])
    @sections = GuidePage.sections
  end
end
