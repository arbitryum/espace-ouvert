# The request form asks different questions for coworking and for association
# activities (Mathilde's lists). Older requests keep message and schedule.
class AddKindFieldsToHostingRequests < ActiveRecord::Migration[8.1]
  def change
    change_table :hosting_requests, bulk: true do |t|
      t.string :first_name, null: false, default: ""
      t.string :last_name, null: false, default: ""
      t.string :activity, null: false, default: ""
      t.text :extra, null: false, default: ""

      # Coworking
      t.string :website, null: false, default: ""
      t.integer :team_size
      t.integer :days_per_week
      t.integer :weekdays, array: true, null: false, default: []
      t.boolean :flexible_days, null: false, default: false
      t.string :needs, array: true, null: false, default: []
      t.string :needs_other, null: false, default: ""
      t.string :compensation

      # Association
      t.text :activity_type, null: false, default: ""
      t.integer :attendees
      t.string :slots, array: true, null: false, default: []
      t.text :contribution, null: false, default: ""
    end
    change_column_default :hosting_requests, :message, from: nil, to: ""
  end
end
