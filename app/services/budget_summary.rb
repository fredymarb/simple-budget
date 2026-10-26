class BudgetSummary
  attr_reader :budget, :month

  def initialize(budget, month)
    @budget = budget
    @month = month
  end

  def call
    {
      total_balance: total_balance,
      monthly_income: monthly_income,
      monthly_expenses: monthly_expenses,
      income_by_category: income_by_category,
      expense_by_category: expense_by_category
    }
  end

  private

  def month_range
    month.beginning_of_month..month.end_of_month
  end

  def transactions
    budget.transactions
  end

  def total_balance
    transactions.sum(:amount_minor)
  end

  def monthly_totals
    @monthly_totals ||= transactions
      .where(date: month_range)
      .group(:kind)
      .sum(:amount_minor)
  end

  def monthly_income
    monthly_totals.fetch("income", 0)
  end

  def monthly_expenses
    monthly_totals.fetch("expense", 0)
  end

  def category_totals
    @category_totals ||= budget.categories
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
  end

  def income_by_category
    category_totals.select do |(_id, _name, kind), _amount|
      kind == "income"
    end
  end

  def expense_by_category
    category_totals.select do |(_id, _name, kind), _amount|
      kind == "expense"
    end
  end
end
