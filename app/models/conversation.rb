class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  scope :active,   -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  before_validation :clamp_params

  validates :model, presence: true
  validates :temperature, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 2.0 }
  validates :top_p, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :presence_penalty, :frequency_penalty,
            numericality: { greater_than_or_equal_to: -2.0, less_than_or_equal_to: 2.0 }

  # 直近 N 件（既定: 20）
  def last_messages(limit = 20)
    messages.order(created_at: :asc).last(limit)
  end

  def params_for_gemini
    {
      model: model,
      temperature: temperature.to_f,
      top_p: top_p.to_f,
      presence_penalty: presence_penalty.to_f,
      frequency_penalty: frequency_penalty.to_f
    }
  end

  private

  def clamp_params
    self.temperature = [[temperature || 0.7, 0.0].max, 2.0].min
    self.top_p = [[top_p || 1.0, 0.0].max, 1.0].min
    self.presence_penalty  = [[presence_penalty  || 0.0, -2.0].max, 2.0].min
    self.frequency_penalty = [[frequency_penalty || 0.0, -2.0].max, 2.0].min
  end
end
