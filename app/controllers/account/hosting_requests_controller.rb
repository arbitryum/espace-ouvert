# The requests sent to the care homes of the signed-in establishment, which
# accepts them (then writes to the visitor) or refuses them (we email the visitor).
class Account::HostingRequestsController < ApplicationController
  before_action :require_authentication
  before_action :set_profile
  before_action :set_pending_request, except: :index

  def index
    @hosting_requests = HostingRequest.for_profile(@profile).includes(:care_home, :space)
  end

  def accept
    @hosting_request.accept!
    redirect_to account_hosting_requests_path(anchor: helpers.dom_id(@hosting_request)), notice: t(".notice", organization: @hosting_request.organization_name)
  end

  def refusal
  end

  def refuse
    @hosting_request.refuse!(params.dig(:hosting_request, :refusal_reason))
    HostingRequestsMailer.refusal(@hosting_request).deliver_later
    redirect_to account_hosting_requests_path, notice: t(".notice", organization: @hosting_request.organization_name)
  end

  private

  # Admins answer nothing here: the back office lists every request.
  def set_profile
    @profile = Current.user.ehpad_profile
    redirect_to root_path, alert: t("account.hosting_requests.no_profile") unless @profile&.approved?
  end

  # Answered requests can't be answered again.
  def set_pending_request
    @hosting_request = HostingRequest.for_profile(@profile).pending.find(params.expect(:id))
  end
end
