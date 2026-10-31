require 'rails_helper'

RSpec.describe Budget, type: :model do
  it "has a valid factory" do
    expect(build(:budget)).to be_valid
  end
end

RSpec.describe Budget, type: :model do
  it "is invalid without a user" do
    budget = build(:budget, user: nil)
    expect(budget).not_to be_valid
  end

  it "is invalid without a name" do
    budget = build(:budget, name: nil)
    expect(budget).not_to be_valid
  end

  it "is invalid without a currency" do
    budget = build(:budget, currency: nil)
    expect(budget).not_to be_valid
  end
end
