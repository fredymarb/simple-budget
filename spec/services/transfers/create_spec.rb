require "rails_helper"

RSpec.describe Transfers::Create do
  let(:budget) { create(:budget) }
  let(:checking) { create(:account, budget: budget, name: "Checking") }
  let(:savings) { create(:account, budget: budget, name: "Savings") }

  def build_transfer(**overrides)
    described_class.new(
      **{ source_account: checking, destination_account: savings, amount_minor: 1_500 }.merge(overrides)
    )
  end

  it "creates paired outgoing and incoming legs sharing a group id" do
    outgoing, incoming = build_transfer(date: Date.new(2026, 10, 1), memo: "Rent share").call

    expect(outgoing).to have_attributes(account: checking, amount_minor: -1_500, kind: "transfer", memo: "Rent share")
    expect(incoming).to have_attributes(account: savings, amount_minor: 1_500, kind: "transfer")
    expect(outgoing.transfer_group_id).to be_present.and eq(incoming.transfer_group_id)
    expect(outgoing.date).to eq(Date.new(2026, 10, 1))
  end

  it "accepts the amount as a string" do
    outgoing, = build_transfer(amount_minor: "250").call

    expect(outgoing.amount_minor).to eq(-250)
  end

  it "rejects a non-integer amount" do
    expect { build_transfer(amount_minor: "1.5") }.to raise_error(ArgumentError, "Amount must be an integer in minor units")
    expect { build_transfer(amount_minor: nil) }.to raise_error(ArgumentError, "Amount must be an integer in minor units")
  end

  it "rejects a non-positive amount" do
    expect { build_transfer(amount_minor: 0).call }.to raise_error(ArgumentError, "Transfer amount must be positive")
  end

  it "requires persisted accounts" do
    expect { build_transfer(source_account: nil).call }.to raise_error(ArgumentError, "Both accounts must exist")
    expect { build_transfer(destination_account: build(:account)).call }.to raise_error(ArgumentError, "Both accounts must exist")
  end

  it "requires different accounts" do
    expect { build_transfer(destination_account: checking).call }
      .to raise_error(ArgumentError, "Source and destination accounts must differ")
  end

  it "requires accounts from the same budget" do
    expect { build_transfer(destination_account: create(:account)).call }
      .to raise_error(ArgumentError, "Accounts must belong to the same budget")
  end

  it "creates nothing when a leg fails" do
    checking
    savings
    allow_any_instance_of(Account).to receive(:transactions).and_wrap_original do |original, *args|
      relation = original.call(*args)
      allow(relation).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      relation
    end

    expect { build_transfer.call }.to raise_error(ActiveRecord::RecordInvalid)
    expect(Transaction.where(kind: :transfer)).to be_empty
  end
end
