class BudgetsController < ApplicationController
  before_action :set_budget, only: [ :show ]

  # def show
  #   @month = month_param(params[:month])
  #   @total_balance = @budget.transactions.sum(:amount_minor)
  #   @monthly_income = @budget.transactions.where(kind: "income", date: @month.beginning_of_month..@month.end_of_month).sum(:amount_minor)
  #   @monthly_expenses = @budget.transactions.where(kind: "expense", date: @month.beginning_of_month..@month.end_of_month).sum(:amount_minor)

  #   @income_categories = @budget.categories.joins(:transactions).where(transactions: { kind: "income", date: @month.beginning_of_month..@month.end_of_month }).distinct
  #   @expense_categories = @budget.categories.joins(:transactions).where(transactions: { kind: "expense", date: @month.beginning_of_month..@month.end_of_month }).distinct
  # end

  def show
    @month = month_param(params[:month])
    month_range = @month.beginning_of_month..@month.end_of_month

    transactions = @budget.transactions

    # Total balance across all transactions.
    @total_balance = transactions.sum(:amount_minor)

    # Calculate monthly income and expenses in one query.
    monthly_totals = transactions
      .where(date: month_range)
      .group(:kind)
      .sum(:amount_minor)

    @monthly_income = monthly_totals.fetch("income", 0)
    @monthly_expenses = monthly_totals.fetch("expense", 0)

    # Calculate totals for every category and transaction kind
    # in a single query.
    category_totals = @budget.categories
      .joins(:transactions)
      .where(
        transactions: {
          date: month_range,
          kind: %w[income expense]
        }
      )
      .group(
        "categories.id",
        "categories.name",
        "transactions.kind"
      )
      .sum("transactions.amount_minor")

    # Separate the results in Ruby, without additional SQL queries.
    @income_by_category = category_totals.select do |(_id, _name, kind), _amount|
      kind == "income"
    end

    @expense_by_category = category_totals.select do |(_id, _name, kind), _amount|
      kind == "expense"
    end
  end

  private

  def set_budget
    @budget = current_user.budget
  end

  def budget_params
    params.require(:budget).permit(:month)
  end
end
