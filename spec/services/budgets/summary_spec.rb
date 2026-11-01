require "rails_helper"

RSpec.describe Budgets::Summary do
  let(:budget) { create(:budget, currency: "USD") }
  let(:checking) { create(:account, budget: budget, name: "Checking") }
  let(:savings) { create(:account, budget: budget, name: "Savings") }
  let(:salary) { create(:category, budget: budget, name: "Salary") }
  let(:rent) { create(:category, budget: budget, name: "Rent") }
  let(:month) { Date.new(2026, 10, 15) }

  def add(kind, amount, category, date: Date.new(2026, 10, 10))
    create(:transaction, kind, budget: budget, account: checking, category: category,
                              amount_minor: amount, date: date)
  end

  subject(:summary) { described_class.new(budget, month).call }

  it "returns zeros and empty groups for an empty budget" do
    expect(summary).to include(total_balance: 0, monthly_income: 0, monthly_expense: 0)
    expect(summary[:income_by_category]).to be_empty
    expect(summary[:expense_by_category]).to be_empty
  end

  it "sums the monthly income and expense for the requested month only" do
    add(:income, 10_000, salary)
    add(:expense, -2_500, rent)
    add(:income, 99_999, salary, date: Date.new(2026, 9, 30))

    expect(summary[:monthly_income]).to eq(10_000)
    expect(summary[:monthly_expense]).to eq(-2_500)
  end

  it "reports the total balance across all months" do
    add(:income, 10_000, salary)
    add(:expense, -2_500, rent, date: Date.new(2026, 9, 1))

    expect(summary[:total_balance]).to eq(7_500)
  end

  it "groups income and expenses by category" do
    add(:income, 10_000, salary)
    add(:income, 500, salary)
    add(:expense, -2_500, rent)

    expect(summary[:income_by_category]).to eq([ salary.id, "Salary", "income" ] => 10_500)
    expect(summary[:expense_by_category]).to eq([ rent.id, "Rent", "expense" ] => -2_500)
  end

  it "ignores transfers in income, expense and the total balance" do
    Transfers::Create.new(source_account: checking, destination_account: savings,
                          amount_minor: 4_000, date: Date.new(2026, 10, 10)).call

    expect(summary).to include(total_balance: 0, monthly_income: 0, monthly_expense: 0)
    expect(summary[:income_by_category]).to be_empty
  end
end
