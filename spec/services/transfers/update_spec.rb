require "rails_helper"

RSpec.describe Transfers::Update do
  let(:budget) { create(:budget) }
  let(:checking) { create(:account, budget: budget, name: "Checking") }
  let(:savings) { create(:account, budget: budget, name: "Savings") }
  let(:wallet) { create(:account, budget: budget, name: "Wallet") }
  let!(:outgoing) do
    Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 1_000,
                          date: Date.new(2026, 10, 1)).call.first
  end

  def update(**overrides)
    described_class.new(
      **{ transaction: outgoing, amount_minor: 2_000, date: "2026-10-05", memo: "Edited" }.merge(overrides)
    ).call
  end

  it "updates amount, date and memo on both legs" do
    legs = update

    expect(legs.map(&:amount_minor)).to contain_exactly(-2_000, 2_000)
    expect(legs.map(&:date).uniq).to eq([ Date.new(2026, 10, 5) ])
    expect(legs.map(&:memo).uniq).to eq([ "Edited" ])
  end

  it "keeps the existing accounts by default" do
    update

    expect(outgoing.reload.account).to eq(checking)
  end

  it "can change both accounts" do
    update(source_account: wallet, destination_account: checking)

    expect(outgoing.reload.account).to eq(wallet)
    expect(Transaction.find_by(transfer_group_id: outgoing.transfer_group_id, amount_minor: 2_000).account).to eq(checking)
  end

  it "accepts a Date and a string amount" do
    update(amount_minor: "300", date: Date.new(2026, 11, 2))

    expect(outgoing.reload).to have_attributes(amount_minor: -300, date: Date.new(2026, 11, 2))
  end

  it "rejects a bad amount" do
    expect { update(amount_minor: "x") }.to raise_error(ArgumentError, "Amount must be an integer in minor units")
    expect { update(amount_minor: 1.5) }.to raise_error(ArgumentError, "Amount must be an integer in minor units")
    expect { update(amount_minor: 0) }.to raise_error(ArgumentError, "Transfer amount must be positive")
  end

  it "rejects a transfer without a group id" do
    outgoing.transfer_group_id = nil

    expect { update }.to raise_error(ArgumentError, "Transfer must have a transfer group ID")
  end

  it "rejects an invalid date" do
    expect { update(date: "nope") }.to raise_error(ArgumentError, "Transfer date must be a date")
    expect { update(date: nil) }.to raise_error(ArgumentError, "Transfer date must be a date")
  end

  it "rejects a transaction that is not a transfer" do
    regular = create(:transaction, budget: budget, account: checking)

    expect { update(transaction: regular) }.to raise_error(ArgumentError, "Transaction must be a persisted transfer")
  end

  it "rejects a transfer with a missing leg" do
    Transaction.where(transfer_group_id: outgoing.transfer_group_id).where("amount_minor > 0").delete_all

    expect { update }.to raise_error(ArgumentError, "Transfer must have exactly two valid transaction records")
  end

  it "requires distinct, persisted, same-budget accounts" do
    expect { update(source_account: savings, destination_account: savings) }
      .to raise_error(ArgumentError, "Source and destination accounts must differ")
    expect { update(source_account: build(:account), destination_account: savings) }
      .to raise_error(ArgumentError, "Both accounts must exist")
    expect { update(source_account: create(:account), destination_account: savings) }
      .to raise_error(ArgumentError, "Accounts must belong to the same budget")
  end
end
