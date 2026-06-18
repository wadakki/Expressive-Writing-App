class WritingEntry < ApplicationRecord
  DETAIL_ATTRIBUTES = %i[
    event_detail
    negative_emotion_detail
    positive_emotion_detail
    unforgiven_target_detail
    tomorrow_hope
  ].freeze

  TIMER_DURATION_SECONDS = 480

  belongs_to :user

  enum :status, { draft: 0, completed: 1 }, default: :draft, validate: true

  validates(*DETAIL_ATTRIBUTES, presence: true, if: :completed?)
  validates(*DETAIL_ATTRIBUTES, length: { maximum: 3000 })
  validates :before_happiness_score, :after_happiness_score,
            presence: true, if: :completed?
  validates :before_happiness_score, :after_happiness_score,
            numericality: { only_integer: true, in: 1..10 }, allow_nil: true
  validates :timer_remaining_seconds,
            numericality: { only_integer: true, in: 0..TIMER_DURATION_SECONDS },
            allow_nil: false
  validate :timer_finished_when_completed

  private

  def timer_finished_when_completed
    return unless completed? && timer_remaining_seconds.to_i.positive?

    errors.add(:timer_remaining_seconds, "はタイマー終了後にしてください")
  end
end
