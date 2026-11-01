require "rails_helper"

RSpec.describe Money do
  describe ".decimal_to_minor" do
    it "converts using the currency exponent" do
      expect(described_class.decimal_to_minor("12.34", exponent: 2)).to eq(1_234)
      expect(described_class.decimal_to_minor("5", exponent: 0)).to eq(5)
      expect(described_class.decimal_to_minor("1.234", exponent: 3)).to eq(1_234)
    end

    it "ignores thousands separators and whitespace" do
      expect(described_class.decimal_to_minor(" 1,234.50 ", exponent: 2)).to eq(123_450)
    end

    it "rounds extra precision" do
      expect(described_class.decimal_to_minor("1.005", exponent: 2)).to eq(101)
    end

    it "rejects non-numeric input" do
      expect { described_class.decimal_to_minor("abc", exponent: 2) }.to raise_error(ArgumentError)
    end

    it "rejects non-finite values" do
      expect { described_class.decimal_to_minor("NaN", exponent: 2) }.to raise_error(ArgumentError, "amount out of range")
    end

    it "rejects amounts beyond the maximum" do
      expect { described_class.decimal_to_minor("1e20", exponent: 2) }.to raise_error(ArgumentError, "amount out of range")
    end
  end

  describe ".minor_to_decimal" do
    it "formats with the exponent" do
      expect(described_class.minor_to_decimal(1_234, exponent: 2)).to eq("12.34")
      expect(described_class.minor_to_decimal(5, exponent: 2)).to eq("0.05")
      expect(described_class.minor_to_decimal(1_234, exponent: 3)).to eq("1.234")
    end

    it "keeps the sign of negative amounts" do
      expect(described_class.minor_to_decimal(-1_234, exponent: 2)).to eq("-12.34")
      expect(described_class.minor_to_decimal(-7, exponent: 0)).to eq("-7")
    end

    it "formats zero-exponent currencies without a fraction" do
      expect(described_class.minor_to_decimal(1_500, exponent: 0)).to eq("1500")
    end
  end

  describe "constants" do
    it "defaults the exponent to 2 and knows special currencies" do
      expect(described_class::EXPONENTS["USD"]).to eq(2)
      expect(described_class::EXPONENTS["JPY"]).to eq(0)
      expect(described_class::EXPONENTS["KWD"]).to eq(3)
    end

    it "has a symbol for every listed currency" do
      expect(described_class::CURRENCIES["USD"]).to eq("$")
    end
  end
end
