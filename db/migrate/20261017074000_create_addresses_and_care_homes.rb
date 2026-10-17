class CreateAddressesAndCareHomes < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :raw_address, null: false
      t.string :label, null: false, default: ""
      t.string :city, null: false, default: ""
      t.string :postal_code, null: false, default: ""
      t.string :city_code, null: false, default: ""
      t.string :department_code, null: false, default: ""
      t.string :department_name, null: false, default: ""
      t.string :region_name, null: false, default: ""
      t.text :search_text, null: false, default: ""
      t.float :latitude
      t.float :longitude
      t.string :ban_id, null: false, default: ""
      t.float :ban_score

      t.timestamps
    end
    add_index :addresses, :raw_address, unique: true

    create_table :care_homes do |t|
      t.string :name, null: false
      t.string :address, null: false
      t.references :address_details, foreign_key: {to_table: :addresses, on_delete: :nullify}
      t.string :legal_status, null: false, default: ""
      t.string :contact_name, null: false, default: ""
      t.string :contact_email, null: false, default: ""
      t.string :group_name, null: false, default: ""

      t.timestamps
    end

    create_table :nonprofit_organizations do |t|
      t.string :name, null: false
      t.string :address, null: false

      t.timestamps
    end
  end
end
