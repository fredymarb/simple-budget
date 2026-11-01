require "rails_helper"

RSpec.describe Transfers::Destroy do
  let(:budget) { create(:budget) }
  let(:checking) { create(:account, budget: budget) }
  let(:savings) { create(:account, budget: budget) }

  it "removes both legs of the transfer" do
    outgoing, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 100).call

    expect { described_class.new(transaction: outgoing).call }.to change(Transaction, :count).by(-2)
  end

  it "leaves other transfers alone" do
    first, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 100).call
    Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 200).call

    expect { described_class.new(transaction: first).call }.to change(Transaction, :count).by(-2)
    expect(Transaction.where(kind: :transfer).count).to eq(2)
  end

  it "rejects a transaction that is not a persisted transfer" do
    regular = create(:transaction, budget: budget, account: checking)

    expect { described_class.new(transaction: regular).call }
      .to raise_error(ArgumentError, "Transaction must be a persisted transfer")
    expect { described_class.new(transaction: build(:transaction, :transfer)).call }
      .to raise_error(ArgumentError, "Transaction must be a persisted transfer")
  end

  it "rejects a transfer without a group id" do
    outgoing, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 100).call
    outgoing.transfer_group_id = nil

    expect { described_class.new(transaction: outgoing).call }
      .to raise_error(ArgumentError, "Transfer must have a transfer group ID")
  end
end
