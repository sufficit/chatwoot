# == Schema Information
#
# Table name: applied_slas
#
#  id              :bigint           not null, primary key
#  sla_status      :integer          default("active")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  sla_policy_id   :bigint           not null
#
# Indexes
#
#  index_applied_slas_on_account_id                       (account_id)
#  index_applied_slas_on_account_sla_policy_conversation  (account_id,sla_policy_id,conversation_id) UNIQUE
#  index_applied_slas_on_conversation_id                  (conversation_id)
#  index_applied_slas_on_sla_policy_id                    (sla_policy_id)
#
class AppliedSla < ApplicationRecord
  belongs_to :account
  belongs_to :sla_policy
  belongs_to :conversation

  has_many :sla_events, dependent: :destroy

  validates :account_id, uniqueness: { scope: %i[sla_policy_id conversation_id] }
  before_validation :ensure_account_id

  enum sla_status: { active: 0, hit: 1, missed: 2 }

  scope :filter_by_date_range, ->(range) { where(created_at: range) if range.present? }
  scope :filter_by_inbox_id, ->(inbox_id) { where(inbox_id: inbox_id) if inbox_id.present? }
  scope :filter_by_team_id, ->(team_id) { where(team_id: team_id) if team_id.present? }
  scope :filter_by_sla_policy_id, ->(sla_policy_id) { where(sla_policy_id: sla_policy_id) if sla_policy_id.present? }
  scope :filter_by_label_list, ->(label_list) { joins(:conversation).where(conversations: { cached_label_list: label_list }) if label_list.present? }
  scope :filter_by_assigned_agent_id, lambda { |assigned_agent_id|
                                        if assigned_agent_id.present?
                                          joins(:conversation).where(conversations: { assigned_agent_id: assigned_agent_id })
                                        end
                                      }
  scope :missed, -> { where(sla_status: :missed) }
  private

  def ensure_account_id
    self.account_id ||= sla_policy&.account_id
  end
end
