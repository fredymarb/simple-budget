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
    Budgets::CreateDefault.call(user: self)
  end
end
