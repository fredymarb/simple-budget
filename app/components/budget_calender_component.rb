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

  def previous_month_url
    month_url(month.prev_month)
  end

  def next_month_url
    month_url(month.next_month)
  end


  private

  def month_url(date)
    request_path = helpers.request.path
    query_params = helpers.request.query_parameters.merge(
      "month" => date.strftime("%Y-%m")
    )
    "#{request_path}?#{query_params.to_query}"
  end
end
