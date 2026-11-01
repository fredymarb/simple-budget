require "rails_helper"

RSpec.describe "Transactions destroy and edge cases", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:budget) { user.budget }
  let(:account) { budget.accounts.first }

  before { sign_in user }

  describe "DELETE /transactions/:id" do
    it "deletes the transaction and returns to the month list" do
      transaction = budget.transactions.first

      expect {
        delete transaction_path(transaction, month: "2026-10")
      }.to change { budget.transactions.count }.by(-1)

      expect(response).to redirect_to(transactions_path(month: "2026-10"))
      expect(flash[:notice]).to eq("Transaction was successfully deleted.")
    end

    it "cannot delete another budget's transaction" do
      foreign = create(:user).budget.transactions.first

      expect {
        delete transaction_path(foreign)
      }.not_to change(Transaction, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /transactions" do
    it "lists this month's regular transactions" do
      get transactions_path(month: Date.current.strftime("%Y-%m"))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Salary", "Rent", "Groceries")
    end

    it "uses the current month when the month is invalid" do
      get transactions_path(month: "bad")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Salary")
    end
  end

  describe "POST /transactions with invalid data" do
    it "re-renders the new form with an error" do
      post transactions_path, params: { transaction: { kind: "income", amount_minor: "100", date: "2026-10-01",
                                                       account_id: account.id } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /transactions/:id with invalid data" do
    it "re-renders the edit form" do
      transaction = budget.transactions.first

      patch transaction_path(transaction), params: { transaction: { amount_minor: "abc", date: "not-a-date",
                                                                    account_id: account.id,
                                                                    category_id: transaction.category_id } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
