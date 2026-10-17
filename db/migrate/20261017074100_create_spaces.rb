class CreateSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :spaces do |t|
      t.references :care_home, null: false, foreign_key: { on_delete: :cascade }
      t.text :name, null: false
      t.text :availability, null: false, default: ""
      t.text :description, null: false, default: ""
      t.datetime :published_at, null: false
      t.string :status, null: false, default: "available"
      t.string :publication_status, null: false, default: "published"

      t.timestamps
    end

    create_table :space_images do |t|
      t.references :space, null: false, foreign_key: { on_delete: :cascade }
      t.string :alt_text, null: false, default: ""
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    # weekday: 0 = Monday … 6 = Sunday (same convention as the Django prototype).
    create_table :recurring_availabilities do |t|
      t.references :space, null: false, foreign_key: { on_delete: :cascade }
      t.integer :weekday, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :notes, null: false, default: ""
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
