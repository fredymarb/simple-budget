require 'rails_helper'

RSpec.describe Category, type: :model do
  it "has a valid factory" do
    expect(build(:category)).to be_valid
  end

  it "is invalid without a name" do
    category = build(:category, name: nil)
    expect(category).not_to be_valid
  end

  it "is invalid without a budget" do
    category = build(:category, budget: nil)
    expect(category).not_to be_valid
  end

  it "is invalid with a duplicate name within the same budget" do
    budget = create(:budget)
    create(:category, budget: budget, name: "Groceries")
    category = build(:category, budget: budget, name: "Groceries")
    expect(category).not_to be_valid
  end

  it "is valid with the same name in different budgets" do
    budget1 = create(:budget)
    budget2 = create(:budget)
    create(:category, budget: budget1, name: "Groceries")
    category = build(:category, budget: budget2, name: "Groceries")
    expect(category).to be_valid
  end
end
