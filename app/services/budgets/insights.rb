module Budgets
  class Insights
    attr_reader :budget, :month

    def initialize(budget, month)
      @budget = budget
      @month = month
    end

    def call
      {
        current_month_summary: current_month_summary,
        monthly_trends: monthly_trends,
        expense_by_category: expense_by_category,
        income_by_category: income_by_category,
        average_monthly_expense: average_monthly_expense,
        average_monthly_income: average_monthly_income,
        savings_rate: savings_rate
      }
    end

    private

    def transactions
      budget.transactions
    end

    def current_month_summary
      month_range = month.beginning_of_month..month.end_of_month
      summary = transactions.where(date: month_range).group(:kind).sum(:amount_minor)

      {
        income: summary.fetch("income", 0),
        expense: summary.fetch("expense", 0),
        net: summary.fetch("income", 0) + summary.fetch("expense", 0)
      }
    end

    def monthly_trends
      (0..11).map do |i|
        month_start = i.months.ago.beginning_of_month
        month_end = month_start.end_of_month
        totals = transactions
          .where(date: month_start..month_end)
          .group(:kind)
          .sum(:amount_minor)

        {
          month: month_start,
          income: totals.fetch("income", 0),
          expense: totals.fetch("expense", 0)
        }
      end.reverse
    end

    def expense_by_category
      month_range = month.beginning_of_month..month.end_of_month
      budget.categories
        .joins(:transactions)
        .where(transactions: { date: month_range, kind: "expense" })
        .group("categories.id", "categories.name")
        .sum("transactions.amount_minor")
        .map { |(id, name), amount| { id: id, name: name, amount: amount.abs } }
        .sort_by { |c| -c[:amount] }
    end

    def income_by_category
      month_range = month.beginning_of_month..month.end_of_month
      budget.categories
        .joins(:transactions)
        .where(transactions: { date: month_range, kind: "income" })
        .group("categories.id", "categories.name")
        .sum("transactions.amount_minor")
        .map { |(id, name), amount| { id: id, name: name, amount: amount } }
        .sort_by { |c| -c[:amount] }
    end

    def average_monthly_expense
      expenses = (0..11).map do |i|
        m = i.months.ago.beginning_of_month
        transactions
          .where(date: m.beginning_of_month..m.end_of_month, kind: "expense")
          .sum(:amount_minor)
      end
      expenses.sum.abs / 12
    end

    def average_monthly_income
      incomes = (0..11).map do |i|
        m = i.months.ago.beginning_of_month
        transactions
          .where(date: m.beginning_of_month..m.end_of_month, kind: "income")
          .sum(:amount_minor)
      end
      incomes.sum / 12
    end

    def savings_rate
      income = average_monthly_income
      expense = average_monthly_expense
      return 0 if income.zero?

      ((income - expense) / income.to_f * 100).round(1)
    end
  end
end
