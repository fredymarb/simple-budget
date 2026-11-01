require "rails_helper"

RSpec.describe "Accounts", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:budget) { user.budget }

  describe "authentication" do
    it "redirects signed-out visitors to sign in" do
      get accounts_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when signed in" do
    before { sign_in user }

    describe "GET /accounts" do
      it "lists the budget's accounts" do
        create(:account, budget: budget, name: "Brokerage")

        get accounts_path(month: "2026-10")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Brokerage", "Default")
      end

      it "falls back to the current month for an invalid month" do
        get accounts_path(month: "nonsense")

        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /accounts/new" do
      it "renders the form" do
        get new_account_path

        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /accounts" do
      it "creates an account in the user's budget" do
        expect {
          post accounts_path, params: { account: { name: "Savings" } }
        }.to change { budget.accounts.count }.by(1)

        expect(response).to redirect_to(accounts_path)
        expect(flash[:notice]).to eq("Account was successfully created.")
      end

      it "re-renders the form when invalid" do
        expect {
          post accounts_path, params: { account: { name: "" } }
        }.not_to change(Account, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /accounts/:id/edit" do
      it "renders the form" do
        account = create(:account, budget: budget, name: "Old name")

        get edit_account_path(account)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Old name")
      end

      it "returns not found for another budget's account" do
        foreign = create(:account)

        get edit_account_path(foreign)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /accounts/:id" do
      let!(:account) { create(:account, budget: budget, name: "Old name") }

      it "updates the account" do
        patch account_path(account), params: { account: { name: "New name" } }

        expect(response).to redirect_to(accounts_path)
        expect(account.reload.name).to eq("New name")
      end

      it "re-renders the form when invalid" do
        patch account_path(account), params: { account: { name: "" } }

        expect(response).to have_http_status(:ok)
        expect(account.reload.name).to eq("Old name")
      end
    end

    describe "DELETE /accounts/:id" do
      it "destroys an empty account" do
        account = create(:account, budget: budget)

        expect {
          delete account_path(account)
        }.to change { budget.accounts.count }.by(-1)

        expect(response).to redirect_to(accounts_path)
      end

      it "keeps an account that has transactions" do
        account = budget.accounts.first

        expect {
          delete account_path(account)
        }.not_to change(Account, :count)
      end
    end
  end
end
