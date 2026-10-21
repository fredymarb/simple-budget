class User < ApplicationRecord
  after_create :set_default_budget

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :budget, dependent: :destroy
  has_many :accounts, through: :budget
  has_many :categories, through: :budget
  has_many :transactions, through: :budget

  private

  def set_default_budget
    categories = [
      "Eating Out", "Groceries", "Entertainment", "E-cash",
      "Gift", "Grooming", "Gym", "Internet", "Miscellaneous",
      "Phone", "Rent", "Salary", "Savings", "Transport", "Utilities"
    ]

    ActiveRecord::Base.transaction do
      # Create a default budget for the current user
      default_budget = create_budget!(name: "My Budget", currency: "USD")

      # Create default account for the new budget
      default_budget.accounts.create!(name: "Default")

      # Create default categories for the new budget
      categories.each do |category|
        default_budget.categories.create!(name: category)
      end
    end
  end
end
