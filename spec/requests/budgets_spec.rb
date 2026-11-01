require "rails_helper"

RSpec.describe "Budgets", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:budget) { user.budget }
  let(:account) { create(:account, budget: budget) }
  let(:category) { create(:category, budget: budget) }

  before { sign_in user }

  describe "GET /budget" do
    it "shows the budget page" do
      get budget_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Total Balance")
    end

    it "shows current month summary" do
      create(:transaction, :income, budget: budget, account: account, category: category,
                                    amount_minor: 100_000, date: Date.current)

      get budget_path
      expect(response.body).to include("100")
    end
  end

  describe "GET /budget/insights" do
    it "shows the insights page" do
      get insights_budget_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Insights")
    end

    it "displays analytics data" do
      create(:transaction, :income, budget: budget, account: account, category: category,
                                    amount_minor: 100_000, date: Date.current)
      create(:transaction, :expense, budget: budget, account: account, category: category,
                                     amount_minor: -5_000, date: Date.current)

      get insights_budget_path
      expect(response.body).to include("Avg Monthly Income")
      expect(response.body).to include("Savings Rate")
    end

    it "filters by month parameter" do
      past_month = 1.month.ago
      create(:transaction, :income, budget: budget, account: account, category: category,
                                    amount_minor: 100_000, date: past_month)

      get insights_budget_path, params: { month: past_month.strftime("%Y-%m") }
      expect(response).to have_http_status(:ok)
    end
  end
end
