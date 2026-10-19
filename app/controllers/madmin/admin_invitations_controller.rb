module Madmin
  class AdminInvitationsController < Madmin::ApplicationController
    def new
      @invitation = AdminInvitation.new
    end

    def create
      @invitation = AdminInvitation.new(params.expect(admin_invitation: [:email_address]))
      if @invitation.save
        redirect_to UserResource.show_path(@invitation.user), notice: t(".notice", email: @invitation.email_address)
      else
        render :new, status: :unprocessable_content
      end
    end
  end
end
