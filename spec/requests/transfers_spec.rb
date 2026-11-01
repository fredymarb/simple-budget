require "rails_helper"

RSpec.describe "Transfers", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:budget) { user.budget }
  let!(:checking) { budget.accounts.first }
  let!(:savings) { create(:account, budget: budget, name: "Savings") }

  before { sign_in user }

  def create_transfer(amount: 2_500)
    Transfers::Create.new(
      source_account: checking, destination_account: savings, amount_minor: amount
    ).call.first
  end

  describe "POST /transfers" do
    it "creates a paired transfer" do
      expect {
        post transfers_path, params: {
          source_account_id: checking.id,
          destination_account_id: savings.id,
          transfer: { amount_minor: "1000", date: "2026-10-01", memo: "Top up" }
        }
      }.to change { budget.transactions.transfer.count }.by(2)

      expect(response).to redirect_to(accounts_path)
      expect(flash[:notice]).to eq("Transfer completed successfully.")
    end

    it "alerts when the accounts are the same" do
      expect {
        post transfers_path, params: {
          source_account_id: checking.id,
          destination_account_id: checking.id,
          transfer: { amount_minor: "1000", date: "2026-10-01" }
        }
      }.not_to change(Transaction, :count)

      expect(flash[:alert]).to eq("Source and destination accounts must differ")
    end
  end

  describe "PATCH /transfers/:id" do
    it "updates both legs" do
      outgoing = create_transfer

      patch transfer_path(outgoing), params: {
        transfer: { amount_minor: "4000", date: "2026-10-02", memo: "Changed" }
      }

      expect(response).to redirect_to(accounts_path)
      expect(flash[:notice]).to eq("Transfer updated successfully.")
      expect(budget.transactions.transfer.pluck(:amount_minor)).to contain_exactly(-4_000, 4_000)
    end

    it "alerts on an invalid amount" do
      outgoing = create_transfer

      patch transfer_path(outgoing), params: { transfer: { amount_minor: "abc", date: "2026-10-02" } }

      expect(flash[:alert]).to eq("Amount must be an integer in minor units")
    end
  end

  describe "DELETE /transfers/:id" do
    it "removes both legs" do
      outgoing = create_transfer

      expect {
        delete transfer_path(outgoing)
      }.to change { budget.transactions.transfer.count }.by(-2)

      expect(flash[:notice]).to eq("Transfer deleted successfully.")
    end

    it "alerts when the transaction is not a transfer" do
      regular = budget.transactions.where.not(kind: :transfer).first

      expect {
        delete transfer_path(regular)
      }.not_to change(Transaction, :count)

      expect(flash[:alert]).to eq("Transaction must be a persisted transfer")
    end
  end
end
