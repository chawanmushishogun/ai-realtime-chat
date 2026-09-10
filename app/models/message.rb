class Message < ApplicationRecord
  enum :role, { user: 0, assistant: 1, system: 2 }

  belongs_to :conversation
  has_many_attached :files
  validates :content, presence: true
end
