require "rails_helper"

RSpec.describe Budgets::Insights do
  let(:budget) { create(:budget, currency: "USD") }
  let(:checking) { create(:account, budget: budget, name: "Checking") }
  let(:salary) { create(:category, budget: budget, name: "Salary") }
  let(:groceries) { create(:category, budget: budget, name: "Groceries") }
  let(:rent) { create(:category, budget: budget, name: "Rent") }
  let(:month) { Date.new(2026, 10, 15) }

  def add(kind, amount, category, date: Date.new(2026, 10, 10))
    create(:transaction, kind, budget: budget, account: checking, category: category,
                              amount_minor: amount, date: date)
  end

  subject(:insights) { described_class.new(budget, month).call }

  it "returns empty data for an empty budget" do
    expect(insights[:current_month_summary]).to eq(income: 0, expense: 0, net: 0)
    expect(insights[:expense_by_category]).to be_empty
    expect(insights[:income_by_category]).to be_empty
    expect(insights[:average_monthly_expense]).to eq(0)
    expect(insights[:average_monthly_income]).to eq(0)
    expect(insights[:savings_rate]).to eq(0)
  end

  it "calculates current month summary" do
    add(:income, 100_000, salary)
    add(:expense, -5_000, groceries)
    add(:expense, -30_000, rent)

    expect(insights[:current_month_summary]).to eq(income: 100_000, expense: -35_000, net: 65_000)
  end

  it "includes only current month transactions in summary" do
    add(:income, 100_000, salary)
    add(:expense, -5_000, groceries)
    add(:income, 50_000, salary, date: Date.new(2026, 9, 10))
    add(:expense, -2_000, groceries, date: Date.new(2026, 11, 10))

    expect(insights[:current_month_summary]).to eq(income: 100_000, expense: -5_000, net: 95_000)
  end

  it "calculates monthly trends for the last 12 months" do
    add(:income, 100_000, salary, date: Date.new(2026, 10, 10))
    add(:income, 100_000, salary, date: Date.new(2026, 5, 10))
    add(:expense, -10_000, groceries, date: Date.new(2026, 10, 10))
    add(:expense, -20_000, groceries, date: Date.new(2026, 5, 10))

    trends = insights[:monthly_trends]
    expect(trends.length).to eq(12)
    
    current = trends.find { |t| t[:month] == Date.new(2026, 10, 1) }
    expect(current).to eq(month: Date.new(2026, 10, 1), income: 100_000, expense: -10_000)

    past = trends.find { |t| t[:month] == Date.new(2026, 5, 1) }
    expect(past).to eq(month: Date.new(2026, 5, 1), income: 100_000, expense: -20_000)
  end

  it "groups expenses by category" do
    add(:expense, -5_000, groceries)
    add(:expense, -3_000, groceries)
    add(:expense, -30_000, rent)

    expect(insights[:expense_by_category]).to match_array([
      { id: rent.id, name: "Rent", amount: 30_000 },
      { id: groceries.id, name: "Groceries", amount: 8_000 }
    ])
  end

  it "groups income by category" do
    add(:income, 100_000, salary)
    add(:income, 5_000, salary)
    add(:income, 2_000, groceries)

    expect(insights[:income_by_category]).to match_array([
      { id: salary.id, name: "Salary", amount: 105_000 },
      { id: groceries.id, name: "Groceries", amount: 2_000 }
    ])
  end

  it "ignores transactions from other months in category breakdown" do
    add(:expense, -10_000, rent)
    add(:expense, -15_000, rent, date: Date.new(2026, 9, 10))

    expect(insights[:expense_by_category]).to eq([
      { id: rent.id, name: "Rent", amount: 10_000 }
    ])
  end

  it "calculates average monthly expense over the last 12 months" do
    add(:expense, -10_000, groceries)
    11.times do |i|
      month_date = (i + 1).months.ago
      add(:expense, -5_000, groceries, date: month_date)
    end

    expected = ((10_000 + 11 * 5_000) / 12).abs
    expect(insights[:average_monthly_expense]).to eq(expected)
  end

  it "calculates average monthly income over the last 12 months" do
    add(:income, 100_000, salary)
    11.times do |i|
      month_date = (i + 1).months.ago
      add(:income, 50_000, salary, date: month_date)
    end

    expected = (100_000 + 11 * 50_000) / 12
    expect(insights[:average_monthly_income]).to eq(expected)
  end

  it "calculates savings rate" do
    12.times do |i|
      month_date = i.zero? ? month : (i).months.ago
      add(:income, 100_000, salary, date: month_date)
      add(:expense, -60_000, rent, date: month_date)
    end

    expect(insights[:savings_rate]).to eq(40.0)
  end

  it "returns 0 savings rate when income is zero" do
    add(:expense, -5_000, groceries)

    expect(insights[:savings_rate]).to eq(0)
  end

  it "handles negative savings rate" do
    12.times do |i|
      month_date = i.zero? ? month : (i).months.ago
      add(:income, 50_000, salary, date: month_date)
      add(:expense, -60_000, rent, date: month_date)
    end

    expect(insights[:savings_rate]).to eq(-20.0)
  end
end
