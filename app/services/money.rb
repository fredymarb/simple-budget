module Money
  include ActionView::Helpers::NumberHelper

  EXPONENTS = Hash.new(2).merge(
    "JPY" => 0, "KRW" => 0, "VND" => 0, "CLP" => 0,
    "KWD" => 3, "BHD" => 3, "OMR" => 3, "JOD" => 3, "TND" => 3
  ).freeze

  MAX_MINOR = 10**14

  module_function

  def decimal_to_minor(string_value, exponent:)
    decimal = BigDecimal(string_value.to_s.delete(",").strip)
    raise ArgumentError, "amount out of range" unless decimal.finite?

    minor = (decimal * 10**exponent).round.to_i
    raise ArgumentError, "amount out of range" if minor.abs > MAX_MINOR

    minor
  end


  def minor_to_decimal(minor, exponent:)
    sign = minor.negative? ? "-" : ""
    return "#{sign}#{minor.abs}" if exponent.zero?

    whole, frac = minor.abs.divmod(10**exponent)
    "#{sign}#{whole}.#{frac.to_s.rjust(exponent, '0')}"
  end
end
