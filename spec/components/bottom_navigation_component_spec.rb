# frozen_string_literal: true

require "rails_helper"

RSpec.describe BottomNavigationComponent, type: :component do
  it "renders" do
    render_inline(described_class.new(month: Date.new(2026, 10, 1)))

    expect(page).to have_css("a")
  end
end
