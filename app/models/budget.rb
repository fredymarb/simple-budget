class Budget < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :currency, presence: true
end
