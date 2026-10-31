require 'rails_helper'

RSpec.describe Transaction, type: :model do
  context "factory" do
    it "has a valid factory" do
      expect(build(:transaction)).to be_valid
    end

    it "creates a valid income transaction" do
      expect(build(:transaction, :income)).to be_valid
    end

    it "creates a valid expense transaction" do
      expect(build(:transaction, :expense)).to be_valid
    end

    it "creates a valid transfer transaction" do
      expect(build(:transaction, :transfer)).to be_valid
    end

    it "is invalid without an amount" do
    transaction = build(:transaction, amount_minor: nil)
    expect(transaction).not_to be_valid
    end

    it "is invalid without a category" do
      transaction = build(:transaction, category: nil)
      expect(transaction).not_to be_valid
    end

    it "is invalid without a date" do
      transaction = build(:transaction, date: nil)
      expect(transaction).not_to be_valid
    end

    it "is invalid with a non-numeric amount" do
      transaction = build(:transaction, amount_minor: "abc")
      expect(transaction).not_to be_valid
    end
  end

  context "income transaction" do
    it "has kind income" do
      transaction = build(:transaction, :income)
      expect(transaction.kind).to eq("income")
    end
  end

  context "expense transaction" do
    it "has kind expense" do
      transaction = build(:transaction, :expense)
      expect(transaction.kind).to eq("expense")
    end
  end

  context "transfer transaction" do
    it "has kind transfer" do
      transaction = build(:transaction, :transfer)
      expect(transaction.kind).to eq("transfer")
    end
    it "is valid without a category for transfer transactions" do
      transaction = build(:transaction, :transfer, category: nil)
      expect(transaction).to be_valid
    end

    it "is valid with a category for transfer transactions" do
      transaction = build(:transaction, :transfer, category: build(:category))
      expect(transaction).to be_valid
    end

    it "is invalid without a category for non-transfer transactions" do
      transaction = build(:transaction, :expense, category: nil)
      expect(transaction).not_to be_valid
    end

    it "requires a transfer_group_id" do
      transaction = build(:transaction, :transfer, transfer_group_id: nil)
      expect(transaction).not_to be_valid
    end
  end
end
