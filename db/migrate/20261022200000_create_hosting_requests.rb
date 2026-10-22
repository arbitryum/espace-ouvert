class CreateHostingRequests < ActiveRecord::Migration[8.1]
  def change
    # The establishment account that manages the care home (set in the back office).
    add_reference :care_homes, :ehpad_profile, foreign_key: {on_delete: :nullify}

    # A visitor's request to be hosted by a care home, sent from its page.
    create_table :hosting_requests do |t|
      t.references :care_home, null: false, foreign_key: {on_delete: :cascade}
      t.references :space, foreign_key: {on_delete: :nullify}
      t.string :kind, null: false, default: "association"
      t.string :organization_name, null: false
      t.string :contact_name, null: false
      t.string :email, null: false
      t.string :phone, null: false, default: ""
      t.text :message, null: false
      t.text :schedule, null: false, default: ""
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :hosting_requests, [:care_home_id, :status]
  end
end
