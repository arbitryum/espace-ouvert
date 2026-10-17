class CreateGuidePagesAndReaders < ActiveRecord::Migration[8.1]
  def change
    # Pages of the coworking guide, imported from Notion (bin/rails guide:import).
    create_table :guide_pages do |t|
      t.string :section, null: false
      t.integer :section_position, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.string :title, null: false
      t.string :slug, null: false
      t.string :icon, null: false, default: ""
      t.text :body, null: false, default: ""

      t.timestamps
    end
    add_index :guide_pages, :slug, unique: true

    # People who asked for the guide; they read it through an emailed link.
    create_table :guide_readers do |t|
      t.string :email_address, null: false
      t.datetime :last_accessed_at

      t.timestamps
    end
    add_index :guide_readers, :email_address, unique: true
  end
end
