# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetCalenderComponent, type: :component do
  it "renders the month label" do
    render_inline(described_class.new(month: Date.new(2026, 10, 15)))

    expect(page).to have_text("October 2026")
  end
end
