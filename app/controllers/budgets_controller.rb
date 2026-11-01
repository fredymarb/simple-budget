class BudgetsController < ApplicationController
  before_action :set_budget, only: [ :show, :insights ]

  def show
    @month = parse_month_param(params[:month])

    summary = Budgets::Summary.new(@budget, @month).call

    @total_balance = summary[:total_balance]
    @monthly_income = summary[:monthly_income]
    @monthly_expense = summary[:monthly_expense]
    @income_by_category = summary[:income_by_category]
    @expense_by_category = summary[:expense_by_category]
  end

  def insights
    @month = parse_month_param(params[:month])
    @insights = Budgets::Insights.new(@budget, @month).call
  end

  private

  def budget_params
    params.require(:budget).permit(:month)
  end
end
