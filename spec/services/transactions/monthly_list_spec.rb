require "rails_helper"

RSpec.describe Transactions::MonthlyList do
  let(:budget) { create(:budget) }
  let(:checking) { create(:account, budget: budget, name: "Checking") }
  let(:savings) { create(:account, budget: budget, name: "Savings") }
  let(:category) { create(:category, budget: budget) }

  it "groups entries by date, newest first, within the month only" do
    create(:transaction, budget: budget, account: checking, category: category, date: Date.new(2026, 10, 5))
    create(:transaction, budget: budget, account: checking, category: category, date: Date.new(2026, 10, 20))
    create(:transaction, budget: budget, account: checking, category: category, date: Date.new(2026, 9, 30))

    result = described_class.new(budget: budget, month: Date.new(2026, 10, 1)).call

    expect(result.keys).to eq([ Date.new(2026, 10, 20), Date.new(2026, 10, 5) ])
  end

  it "lists a transfer once with both account names" do
    Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 100,
                          date: Date.new(2026, 10, 5)).call

    entries = described_class.new(budget: budget, month: Date.new(2026, 10, 1)).call.values.flatten

    expect(entries.size).to eq(1)
    expect(entries.first).to have_attributes(source_name: "Checking", destination_name: "Savings")
    expect(entries.first).to be_transfer
  end
end
