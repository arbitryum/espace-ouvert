class RegistrationsController < ApplicationController
  def new
    @registration = EhpadRegistration.new
  end

  def create
    @registration = EhpadRegistration.new(registration_params)
    if @registration.save
      notice = [t(".notice"), (t(".coworking_notice") if @registration.coworking?)].compact.join(" ")
      redirect_to pending_registration_path, notice:
    else
      render :new, status: :unprocessable_content
    end
  end

  def pending
  end

  private

  def registration_params
    params.expect(ehpad_registration: [:establishment_name, :legal_status, :group_name, :street, :postal_code, :city,
      :contact_name, :email_address, :password, :password_confirmation, :coworking_space,
      {modules: [], coworking_photos: [], spaces: [[:name, :description, {photos: []}, {slots: [[:enabled, :start_time, :end_time]]}]]}])
  end
end
