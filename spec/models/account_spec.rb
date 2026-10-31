require 'rails_helper'

RSpec.describe Account, type: :model do
  it "has a valid factory" do
    expect(build(:account)).to be_valid
  end

  it "is invalid without a budget" do
    account = build(:account, budget: nil)
    expect(account).not_to be_valid
  end

  it "is invalid without a name" do
    account = build(:account, name: nil)
    expect(account).not_to be_valid
  end
end
