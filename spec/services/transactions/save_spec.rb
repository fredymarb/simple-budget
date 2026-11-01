require "rails_helper"

RSpec.describe Transactions::Save do
  let(:budget) { create(:budget, currency: "USD") }
  let(:checking) { create(:account, budget: budget, name: "Checking") }
  let(:savings) { create(:account, budget: budget, name: "Savings") }
  let(:category) { create(:category, budget: budget) }

  def params_for(attributes)
    ActionController::Parameters.new(attributes).permit!
  end

  def save(transaction: nil, **attributes)
    described_class.new(budget: budget, params: params_for(attributes), transaction: transaction).call
  end

  describe "creating" do
    it "creates an income transaction and reports the month" do
      result = save(kind: "income", account_id: checking.id, category_id: category.id, amount: "5.00", date: "2026-10-25")

      expect(result).to be_success
      expect(result.month).to eq("2026-10")
      expect(result.notice).to eq("Transaction was successfully created.")
      expect(result.transaction).to have_attributes(amount_minor: 500)
    end

    it "converts a decimal amount to minor units" do
      result = save(kind: "income", account_id: checking.id, category_id: category.id,
                    amount: "12.34", date: "2026-10-25")

      expect(result).to be_success
      expect(result.transaction.amount_minor).to eq(1_234)
    end

    it "rejects an invalid amount" do
      result = save(kind: "income", account_id: checking.id, category_id: category.id,
                    amount: "abc", date: "2026-10-25")

      expect(result).not_to be_success
      expect(result.error).to eq("Enter a valid amount.")
      expect(result.submitted).to include(amount: "abc")
    end

    it "rejects an unknown kind" do
      result = save(kind: "starting_balance", account_id: checking.id, amount: "5.00", date: "2026-10-25")

      expect(result).not_to be_success
      expect(result.error).to eq("Select a valid transaction type.")
    end

    it "ignores accounts from another budget" do
      foreign = create(:account)
      category
      result = nil
      expect {
        result = save(kind: "income", account_id: foreign.id, category_id: category.id, amount: "5.00", date: "2026-10-25")
      }.not_to change { Transaction.count }

      expect(result).not_to be_success
    end

    it "creates both legs of a transfer" do
      result = save(kind: "transfer", source_account_id: checking.id, destination_account_id: savings.id,
                    amount: "7.00", date: "2026-10-25")

      expect(result).to be_success
      expect(result.notice).to eq("Transfer completed successfully.")
      expect(budget.transactions.transfer.pluck(:amount_minor)).to contain_exactly(-700, 700)
    end

    it "fails a transfer between the same account and keeps submitted values" do
      result = save(kind: "transfer", source_account_id: checking.id, destination_account_id: checking.id,
                    amount: "7.00", date: "2026-10-25")

      expect(result).not_to be_success
      expect(result.error).to eq("Source and destination accounts must differ")
      expect(result.submitted).to include(amount: "7.00", date: "2026-10-25")
    end

    it "fails a transfer with an invalid date" do
      checking
      savings

      result = nil
      expect {
        result = save(kind: "transfer", source_account_id: checking.id, destination_account_id: savings.id,
                      amount: "7.00", date: "not-a-date")
      }.not_to change { Transaction.count }

      expect(result).not_to be_success
    end
  end

  describe "updating" do
    it "updates a regular transaction without changing its kind" do
      transaction = create(:transaction, budget: budget, account: checking, category: category, kind: :expense)

      result = save(transaction: transaction, kind: "transfer", account_id: checking.id, category_id: category.id,
                    amount: "9.00", date: "2026-10-26")

      expect(result).to be_success
      expect(transaction.reload).to have_attributes(kind: "expense", amount_minor: 900)
    end

    it "moves both legs of a transfer" do
      outgoing, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 100,
                                        date: Date.new(2026, 10, 1)).call

      result = save(transaction: outgoing, source_account_id: savings.id, destination_account_id: checking.id,
                    amount: "3.00", date: "2026-10-02")

      expect(result).to be_success
      expect(result.notice).to eq("Transfer was successfully updated.")
      legs = budget.transactions.where(transfer_group_id: outgoing.transfer_group_id).pluck(:account_id, :amount_minor)
      expect(legs).to contain_exactly([ savings.id, -300 ], [ checking.id, 300 ])
    end

    it "requires both accounts when editing a transfer" do
      outgoing, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 100,
                                        date: Date.new(2026, 10, 1)).call

      result = save(transaction: outgoing, source_account_id: checking.id, destination_account_id: "",
                    amount: "3.00", date: "2026-10-02")

      expect(result).not_to be_success
      expect(result.error).to eq("Both accounts must exist.")
    end
  end
end
