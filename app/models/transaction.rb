class Transaction < ApplicationRecord
  belongs_to :budget
  belongs_to :account
  belongs_to :category, optional: true

  enum :kind, { starting_balance: 0, income: 1, expense: 2, transfer: 3 }

  validates :kind, presence: true
  validates :amount_minor, presence: true, numericality: { only_integer: true }
  validates :date, presence: true
  validates :transfer_group_id, presence: true, if: :transfer?
  validates :transfer_group_id, absence: true, unless: :transfer?
end
