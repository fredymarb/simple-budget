module ApplicationHelper
  module_function

  def currency_symbol
    Money::CURRENCIES.fetch(current_user.budget.currency)
  end
end
