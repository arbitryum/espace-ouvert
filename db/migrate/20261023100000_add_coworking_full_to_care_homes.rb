class AddCoworkingFullToCareHomes < ActiveRecord::Migration[8.1]
  def change
    # Can't take another coworking team for now: tagged "Complet" in the directory.
    add_column :care_homes, :coworking_full, :boolean, null: false, default: false
  end
end
