class AddSettingsToConversations < ActiveRecord::Migration[7.2]
  def change
    change_table :conversations, bulk: true do |t|
      t.text    :system_prompt, null: false, default: "あなたは親切で簡潔に答えるアシスタントです。"
      t.string  :model, null: false, default: "gemini-2.5-flash"
      t.decimal :temperature, precision: 2, scale: 1, null: false, default: 0.7
      t.decimal :top_p, precision: 2, scale: 1, null: false, default: 1.0
      t.decimal :presence_penalty, precision: 2, scale: 1, null: false, default: 0.0
      t.decimal :frequency_penalty, precision: 2, scale: 1, null: false, default: 0.0
    end
  end
end
