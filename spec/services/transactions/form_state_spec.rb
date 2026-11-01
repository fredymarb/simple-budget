require "rails_helper"

RSpec.describe Transactions::FormState do
  let(:budget) { create(:budget) }
  let(:checking) { create(:account, budget: budget, name: "Checking") }
  let(:savings) { create(:account, budget: budget, name: "Savings") }

  def state(transaction: budget.transactions.new(date: Date.new(2026, 10, 1)), **options)
    described_class.new(budget: budget, transaction: transaction, **options)
  end

  it "lists the budget's accounts and categories alphabetically" do
    savings
    checking
    create(:category, budget: budget, name: "Zoo")
    create(:category, budget: budget, name: "Art")

    expect(state.accounts.map(&:name)).to eq(%w[Checking Savings])
    expect(state.categories.map(&:name)).to eq(%w[Art Zoo])
  end

  context "for a new transaction" do
    it "has no amount and uses the transaction's date" do
      expect(state.amount_value).to be_nil
      expect(state.date_value).to eq(Date.new(2026, 10, 1))
      expect(state.source_account_id).to be_nil
      expect(state.error).to be_nil
    end
  end

  context "after a failed submission" do
    it "redisplays the submitted values and error" do
      submitted = { amount_minor: "12", date: "2026-10-09", source_account_id: "1", destination_account_id: "2" }
      result = state(error: "Nope", submitted: submitted)

      expect(result).to have_attributes(amount_value: "12", date_value: "2026-10-09",
                                        source_account_id: "1", destination_account_id: "2", error: "Nope")
    end

    it "tolerates nil submitted values" do
      expect(state(submitted: nil).amount_value).to be_nil
    end
  end

  context "for a persisted transfer" do
    let!(:outgoing) do
      Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 700).call.first
    end

    it "loads both accounts and the absolute amount" do
      result = state(transaction: outgoing)

      expect(result.amount_value).to eq(700)
      expect(result.source_account_id).to eq(checking.id)
      expect(result.destination_account_id).to eq(savings.id)
      expect(result.error).to be_nil
    end

    it "reports an incomplete transfer" do
      Transaction.where(transfer_group_id: outgoing.transfer_group_id).where("amount_minor > 0").delete_all

      expect(state(transaction: outgoing).error).to eq("This transfer is incomplete and cannot be edited.")
    end
  end

  it "does not look up a transfer pair for a regular transaction" do
    transaction = create(:transaction, budget: budget, account: checking)

    expect(state(transaction: transaction).source_account_id).to be_nil
    expect(state(transaction: transaction).amount_value).to eq(10_000)
  end
end
