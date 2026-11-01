require "rails_helper"

RSpec.describe "Transactions", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:budget) { create(:budget, user: user, currency: "USD") }
  let(:source_account) { create(:account, budget: budget, name: "Checking") }
  let(:destination_account) { create(:account, budget: budget, name: "Savings") }
  let(:category) { create(:category, budget: budget) }

  before do
    sign_in user
  end

  describe "GET /transactions/new" do
    it "offers the three supported transaction kinds" do
      get new_transaction_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Income", "Expense", "Transfer", "From account", "To account")
    end
  end

  describe "POST /transactions" do
    it "creates a transfer as a pair of account transactions" do
      source_account
      destination_account

      expect {
        post transactions_path, params: {
          transaction: {
            kind: "transfer",
            source_account_id: source_account.id,
            destination_account_id: destination_account.id,
            amount: "12.50",
            date: "2026-10-25",
            memo: "Savings"
          }
        }
      }.to change { budget.transactions.where(kind: :transfer).count }.by(2)

      expect(response).to redirect_to(transactions_path(month: "2026-10"))
      pair = budget.transactions.where(kind: :transfer).order(:amount_minor)
      expect(pair.pluck(:account_id, :amount_minor)).to contain_exactly(
        [ source_account.id, -1250 ],
        [ destination_account.id, 1250 ]
      )
    end

    it "does not create a transfer when both selected accounts are the same" do
      source_account

      expect {
        post transactions_path, params: {
          transaction: {
            kind: "transfer",
            source_account_id: source_account.id,
            destination_account_id: source_account.id,
            amount: "12.50",
            date: "2026-10-25"
          }
        }
      }.not_to change { budget.transactions.where(kind: :transfer).count }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Source and destination accounts must differ")
    end

    it "creates an income transaction with its category and account" do
      post transactions_path, params: {
        transaction: {
          kind: "income",
          account_id: source_account.id,
          category_id: category.id,
          amount: "50.25",
          date: "2026-10-25"
        }
      }

      expect(response).to redirect_to(transactions_path(month: "2026-10"))
      expect(budget.transactions.last).to have_attributes(
        kind: "income",
        account_id: source_account.id,
        category_id: category.id,
        amount_minor: 5025
      )
    end

    it "does not allow using an account from another budget" do
      foreign_account = create(:account, name: "Other budget")

      expect {
        post transactions_path, params: {
          transaction: {
            kind: "income",
            account_id: foreign_account.id,
            category_id: category.id,
            amount: "50.00",
            date: "2026-10-25"
          }
        }
      }.not_to change { budget.transactions.count }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a non-scalar account id" do
      expect {
        post transactions_path, params: {
          transaction: {
            kind: "income",
            account_id: { id: source_account.id },
            category_id: category.id,
            amount: "50.00",
            date: "2026-10-25"
          }
        }
      }.not_to change { budget.transactions.count }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /transactions" do
    it "shows a paired transfer once with both account names" do
      source_account
      destination_account
      Transfers::Create.new(
        source_account: source_account,
        destination_account: destination_account,
        amount_minor: 1250,
        date: Date.new(2026, 10, 25)
      ).call

      get transactions_path(month: "2026-10")

      expect(response).to have_http_status(:ok)
      expect(response.body.scan("Transfer: Checking").size).to eq(1)
      expect(response.body).to include("Savings")
    end
  end

  describe "GET /transactions/:id/edit" do
    it "preselects both accounts of a transfer and fixes its kind" do
      source_account
      destination_account
      outgoing, = Transfers::Create.new(
        source_account: source_account,
        destination_account: destination_account,
        amount_minor: 1500,
        date: Date.new(2026, 10, 20)
      ).call

      get edit_transaction_path(outgoing)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<span class="kind-badge">Transfer</span>')
      expect(response.body).to match(/<option selected="selected" value="#{source_account.id}">Checking/)
      expect(response.body).to match(/<option selected="selected" value="#{destination_account.id}">Savings/)
      expect(response.body).to include('name="transaction[amount]"')
      expect(response.body).to include('value="15.00"')
    end
  end

  describe "PATCH /transactions/:id" do
    it "updates both sides when editing a transfer's accounts" do
      source_account
      destination_account
      new_source = create(:account, budget: budget, name: "Cash")
      new_destination = create(:account, budget: budget, name: "Reserve")
      outgoing, = Transfers::Create.new(
        source_account: source_account,
        destination_account: destination_account,
        amount_minor: 1000,
        date: Date.new(2026, 10, 20)
      ).call

      patch transaction_path(outgoing), params: {
        transaction: {
          source_account_id: new_source.id,
          destination_account_id: new_destination.id,
          amount: "25.00",
          date: "2026-10-27",
          memo: "Updated transfer"
        }
      }

      expect(response).to redirect_to(transactions_path(month: "2026-10"))
      expect(budget.transactions.where(transfer_group_id: outgoing.transfer_group_id).pluck(:account_id, :amount_minor, :memo))
        .to contain_exactly(
          [ new_source.id, -2500, "Updated transfer" ],
          [ new_destination.id, 2500, "Updated transfer" ]
        )
    end

    it "does not allow changing the kind of an existing transaction" do
      transaction = create(
        :transaction,
        budget: budget,
        account: source_account,
        category: category,
        kind: :expense
      )

      patch transaction_path(transaction), params: {
        transaction: {
          kind: "transfer",
          account_id: source_account.id,
          category_id: category.id,
          amount: "30.00",
          date: "2026-10-28"
        }
      }

      expect(response).to redirect_to(transactions_path(month: "2026-10"))
      expect(transaction.reload).to be_expense
    end
  end
end
