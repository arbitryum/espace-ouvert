class AddAnswerToHostingRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :hosting_requests, :answered_at, :datetime
    # Why the care home refused, for Espace-ouvert only: not sent to the visitor.
    add_column :hosting_requests, :refusal_reason, :text, null: false, default: ""
  end
end
