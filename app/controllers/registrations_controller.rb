class RegistrationsController < ApplicationController
  def new
    @registration = EhpadRegistration.new
  end

  def create
    @registration = EhpadRegistration.new(registration_params)
    if @registration.save
      redirect_to pending_registration_path, notice: "Votre demande a été envoyée. Elle sera examinée par notre équipe."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def pending
  end

  private
    def registration_params
      params.expect(ehpad_registration: [ :establishment_name, :establishment_address, :contact_name,
        :username, :email_address, :password, :password_confirmation, modules: [] ])
    end
end
