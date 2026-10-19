class Budget < ApplicationRecord
  belongs_to :user
  has_many :accounts, dependent: :restrict_with_error
  has_many :categories, dependent: :restrict_with_error
  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :currency, presence: true
end
