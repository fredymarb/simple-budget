require "rails_helper"

RSpec.describe "Model associations and constraints", type: :model do
  let(:user) { create(:user) }
  let(:budget) { user.budget }

  it "links a user to its budget's accounts, categories and transactions" do
    expect(user.accounts).to match_array(budget.accounts)
    expect(user.categories).to match_array(budget.categories)
    expect(user.transactions).to match_array(budget.transactions)
  end

  it "prevents deleting an account that has transactions" do
    account = budget.accounts.first

    expect(account.destroy).to be(false)
    expect(account.errors[:base]).to be_present
  end

  it "prevents deleting a category that has transactions" do
    expect(budget.categories.find_by!(name: "Salary").destroy).to be(false)
  end

  it "requires unique account and category names per budget" do
    expect(build(:account, budget: budget, name: "Default")).not_to be_valid
    expect(build(:category, budget: budget, name: "Salary")).not_to be_valid
    expect(build(:account, budget: create(:budget), name: "Default")).to be_valid
  end

  it "validates transfer group ids by kind" do
    account = budget.accounts.first

    expect(build(:transaction, :transfer, budget: budget, account: account, transfer_group_id: nil)).not_to be_valid
    expect(build(:transaction, :income, budget: budget, account: account, transfer_group_id: SecureRandom.uuid)).not_to be_valid
  end
end
