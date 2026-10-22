class HostingRequestsController < ApplicationController
  # The form emails a care home: keep floods out.
  rate_limit to: 5, within: 1.hour, only: :create,
    with: -> { redirect_to care_home_path(params[:care_home_id]), alert: t("hosting_requests.create.too_many") }

  before_action :set_care_home

  def new
    space = @care_home.spaces.listed.find_by(id: params[:space_id])
    kind = params[:kind].presence_in(HostingRequest.kinds.keys)
    # Without a kind in the URL, the default (association) applies.
    @hosting_request = @care_home.hosting_requests.new({space:, kind:}.compact)
  end

  def create
    @hosting_request = @care_home.hosting_requests.new(hosting_request_params)
    # Bots fill the hidden "website_url" field, which people never see: pretend it worked.
    if params[:website_url].present?
      redirect_to @care_home, notice: t(".notice")
    elsif @hosting_request.save
      HostingRequestsMailer.received(@hosting_request).deliver_later
      HostingRequestsMailer.acknowledgment(@hosting_request).deliver_later
      redirect_to @care_home, notice: t(".notice")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_care_home
    @care_home = CareHome.find(params.expect(:care_home_id))
  end

  def hosting_request_params
    params.expect(hosting_request: [:kind, :first_name, :last_name, :email, :organization_name, :activity, :extra,
      :website, :team_size, :days_per_week, :flexible_days, :needs_other, :compensation, {weekdays: [], needs: []},
      :space_id, :activity_type, :attendees, :contribution, :schedule, {slots: []}])
  end
end
