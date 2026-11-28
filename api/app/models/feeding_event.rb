class FeedingEvent < ApplicationRecord
  AMOUNT_ML_RANGE = 0..500
  CLIENT_REQUEST_ID_MAX_LENGTH = 64
  # ミルク / 母乳 / 混合(母乳のあとにミルクを足す)
  KINDS = %w[formula breast mixed].freeze
  RETENTION = 90.days # 保持期間(F-DATA-3)
  DELETED_GRACE = 24.hours # 論理削除してから、物理削除するまで

  belongs_to :family
  belongs_to :child
  # 利用者が削除されると NULL になる(履歴は残す)。作成時は必須
  belongs_to :recorded_by, class_name: "User", optional: true

  enum :kind, KINDS.index_with(&:itself), validate: true

  # 母乳の量は記録しない(F-FEED-4)。母乳に変えたときも量を空にする。DB の CHECK でも保証している
  before_validation { self.amount_ml = nil if breast? }

  # 論理削除は default_scope にせず、明示的に絞り込む(design.md 4.6)
  scope :active, -> { where(deleted_at: nil) }

  validates :recorded_by, presence: true, on: :create
  validates :fed_at, :operation_id, presence: true
  validates :client_request_id, presence: true, length: { maximum: CLIENT_REQUEST_ID_MAX_LENGTH }
  validates :amount_ml, numericality: { only_integer: true, in: AMOUNT_ML_RANGE }, allow_nil: true
  validate :child_belongs_to_family

  def deleted?
    deleted_at.present?
  end

  private
    # DB の複合外部キーでも保証している。ここでは分かりやすいエラーを返すため
    def child_belongs_to_family
      return if child.nil? || family_id.nil?

      errors.add(:child, :invalid) if child.family_id != family_id
    end
end
