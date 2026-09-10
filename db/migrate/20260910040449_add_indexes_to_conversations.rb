class AddIndexesToConversations < ActiveRecord::Migration[7.2]
  def change
    add_index :conversations, :updated_at
    add_index :conversations, :title
  end
end
