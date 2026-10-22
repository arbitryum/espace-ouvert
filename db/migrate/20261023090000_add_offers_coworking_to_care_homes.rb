class AddOffersCoworkingToCareHomes < ActiveRecord::Migration[8.1]
  def change
    # Has a closed space for a small coworking team (registration form):
    # puts the care home in the coworking directory.
    add_column :care_homes, :offers_coworking, :boolean, null: false, default: false
  end
end
