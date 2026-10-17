# Users sign in with their email address, which must therefore be unique.
class RemoveUsernameFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :username, unique: true
    remove_column :users, :username, :string
    remove_index :users, :email_address
    add_index :users, :email_address, unique: true
  end
end
