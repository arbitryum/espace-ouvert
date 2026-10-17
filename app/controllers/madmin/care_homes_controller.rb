module Madmin
  class CareHomesController < Madmin::ResourceController
    private
      # Geocodes the address after saving a new care home or a changed address.
      def save_record(attributes)
        geocode = @record.new_record? || @record.address != attributes["address"] || @record.address_details.nil?
        super.tap { |saved| refresh_address_details if saved && geocode }
      end

      def refresh_address_details
        flash[:alert] = "Aucun résultat de géocodage pour cette adresse." if @record.refresh_address_details!.nil?
      rescue Geocoder::Error => error
        flash[:alert] = error.message
      end
  end
end
