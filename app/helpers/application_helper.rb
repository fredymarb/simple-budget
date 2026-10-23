module ApplicationHelper
  module_function

  def currency_name
    current_user.budget.currency
  end

  def currency_symbol
    Money::CURRENCIES.fetch(current_user.budget.currency)
  end

  def display_money(amount_minor)
    amount_decimal = Money.minor_to_decimal(amount_minor, exponent: Money::EXPONENTS[currency_name])
    "#{currency_symbol} #{amount_decimal}"
  end
end
