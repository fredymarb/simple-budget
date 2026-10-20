# frozen_string_literal: true

# Component for rendering a budget calendar with navigation between months
class BudgetCalenderComponent < ViewComponent::Base
  attr_reader :month

  def initialize(month:)
    @month = month.beginning_of_month
  end

  # Returns the label for the current month in "Month Year" format, e.g., "January 2024"
  def label
    month.strftime("%B %Y")
  end

  # Returns the URL for the previous month's budget page
  def previous_month_url
    helpers.budget_path(month: month.prev_month.strftime("%Y-%m"))
  end

  # Returns the URL for the next month's budget page
  def next_month_url
    helpers.budget_path(month: month.next_month.strftime("%Y-%m"))
  end
end
