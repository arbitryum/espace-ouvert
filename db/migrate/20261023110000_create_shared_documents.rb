class CreateSharedDocuments < ActiveRecord::Migration[8.1]
  def change
    # Documents offered to associations on the directory page (hosting
    # agreement, living-together guide…), uploaded in the back office.
    create_table :shared_documents do |t|
      t.string :title, null: false
      t.text :description, null: false, default: ""
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: false
      t.timestamps
    end
  end
end
