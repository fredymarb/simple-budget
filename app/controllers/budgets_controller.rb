class BudgetsController < ApplicationController
  before_action :set_budget, only: [ :show ]

  def show
    @month = month_param(params[:month])
    @total_balance = @budget.transactions.sum(:amount_minor)
    @monthly_income = @budget.transactions.where(kind: "income", date: @month.beginning_of_month..@month.end_of_month).sum(:amount_minor)
    @monthly_expenses = @budget.transactions.where(kind: "expense", date: @month.beginning_of_month..@month.end_of_month).sum(:amount_minor)

    @income_categories = @budget.categories.joins(:transactions).where(transactions: { kind: "income", date: @month.beginning_of_month..@month.end_of_month }).distinct
    @expense_categories = @budget.categories.joins(:transactions).where(transactions: { kind: "expense", date: @month.beginning_of_month..@month.end_of_month }).distinct
  end

  private

  def month_param(value)
    Date.strptime("#{value}-01", "%Y-%m")
  rescue ArgumentError, TypeError
    Date.today.beginning_of_month
  end

  def set_budget
    @budget = current_user.budget
  end

  def budget_params
    params.require(:budget).permit(:month)
  end
end
