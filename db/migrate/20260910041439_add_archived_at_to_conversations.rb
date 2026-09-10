class AddArchivedAtToConversations < ActiveRecord::Migration[7.2]
  def change
    add_column :conversations, :archived_at, :datetime
    add_index  :conversations, :archived_at
  end
end
