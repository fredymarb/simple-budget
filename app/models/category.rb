class Category < ApplicationRecord
  belongs_to :budget

  validates :name, presence: true, uniqueness: { scope: :budget_id }
end
