class WritingEntry < ApplicationRecord
  DETAIL_ATTRIBUTES = %i[
    event_detail
    negative_emotion_detail
    positive_emotion_detail
    unforgiven_target_detail
    tomorrow_hope
  ].freeze

  belongs_to :user

  enum :status, { draft: 0, completed: 1 }, default: :draft, validate: true

  validates(*DETAIL_ATTRIBUTES, length: { maximum: 3000 })
  validates :before_happiness_score, :after_happiness_score,
            numericality: { only_integer: true, in: 1..10 },
            allow_nil: true
end
