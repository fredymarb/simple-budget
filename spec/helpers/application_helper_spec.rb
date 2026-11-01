require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:user) { create(:user) }

  before do
    user.budget.update!(currency: currency)
    allow(helper).to receive(:current_user).and_return(user)
  end

  context "with USD" do
    let(:currency) { "USD" }

    it "exposes the currency name and symbol" do
      expect(helper.currency_name).to eq("USD")
      expect(helper.currency_symbol).to eq("$")
    end

    it "formats minor units" do
      expect(helper.display_money(12_345)).to eq("$ 123.45")
      expect(helper.display_money(-50)).to eq("$ -0.50")
    end
  end

  context "with a zero-decimal currency" do
    let(:currency) { "JPY" }

    it "formats without a fraction" do
      expect(helper.display_money(1_500)).to eq("¥ 1500")
    end
  end
end
