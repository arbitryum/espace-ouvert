class CreateCoworkingProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :coworking_projects do |t|
      t.string :name, null: false
      t.string :organization_name, null: false
      t.text :description, null: false
      t.string :location, null: false
      t.references :care_home, foreign_key: { on_delete: :nullify }
      t.string :status, null: false, default: "draft"
      t.boolean :published, null: false, default: false

      t.timestamps
    end
  end
end
