require "rails_helper"

RSpec.describe Budgets::CreateDefault do
  let(:user) { create(:user) }
  let(:budget) { user.budget }

  it "is applied automatically when a user is created" do
    expect(budget).to be_persisted
  end

  it "builds a USD budget named 'My Budget'" do
    expect(budget).to have_attributes(name: "My Budget", currency: "USD")
  end

  it "creates the default account and categories" do
    expect(budget.accounts.pluck(:name)).to eq([ "Default" ])
    expect(budget.categories.pluck(:name)).to match_array(described_class::CATEGORY_NAMES)
  end

  it "seeds three sample transactions" do
    expect(budget.transactions.count).to eq(3)
    expect(budget.transactions.sum(:amount_minor)).to eq(40_000)
  end
end
