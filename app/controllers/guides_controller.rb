class GuidesController < ApplicationController
  include GuideAccess

  def index
    @sections = GuidePage.sections if guide_access?
  end

  def show
    return redirect_to guide_path unless guide_access?

    @page = GuidePage.find_by!(slug: params[:slug])
    @sections = GuidePage.sections
  end
end
