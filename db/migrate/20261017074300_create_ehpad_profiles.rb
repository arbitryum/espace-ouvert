class CreateEhpadProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :ehpad_profiles do |t|
      t.references :user, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :establishment_name, null: false
      t.string :establishment_address, null: false
      t.string :contact_name, null: false
      t.string :status, null: false, default: "pending"
      t.boolean :participates_in_spaces, null: false, default: false
      t.boolean :participates_in_coworking, null: false, default: false

      t.timestamps
    end
  end
end
