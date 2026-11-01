require "rails_helper"

RSpec.describe "Budgets", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  describe "GET /budget" do
    it "redirects signed-out visitors to sign in" do
      get budget_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the summary for the requested month" do
      sign_in user
      budget = user.budget
      salary = budget.categories.find_by!(name: "Salary")
      create(:transaction, :income, budget: budget, account: budget.accounts.first,
                                    category: salary, amount_minor: 5_000, date: Date.new(2026, 10, 5))

      get budget_path(month: "2026-10")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Salary", "$ 50.00")
    end

    it "falls back to the current month for an invalid month" do
      sign_in user

      get budget_path(month: "garbage")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Date.current.strftime("%B %Y"))
    end
  end

  describe "root" do
    it "renders the budget for a signed-in user" do
      sign_in user

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end
end
