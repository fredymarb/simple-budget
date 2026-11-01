require "rails_helper"

RSpec.describe TransactionListItemComponent, type: :component do
  let(:user) { create(:user) }
  let(:budget) { user.budget }
  let(:checking) { budget.accounts.first }
  let(:savings) { create(:account, budget: budget, name: "Savings") }

  before do
    allow_any_instance_of(described_class).to receive(:helpers).and_return(
      double(display_money: "$ 10.00").tap do |helpers|
        allow(helpers).to receive(:display_money) { |amount| "$ #{amount}" }
      end
    )
  end

  def entry_for(transaction, source: nil, destination: nil)
    Transactions::MonthlyList::Entry.new(transaction, source, destination)
  end

  it "renders a regular transaction with its category and amount" do
    transaction = budget.transactions.find_by!(memo: "Monthly rent")

    render_inline(described_class.new(entry: entry_for(transaction)))

    expect(page).to have_link("Rent: $ -40000", href: "/transactions/#{transaction.id}/edit")
  end

  it "renders a transfer with both account names and an absolute amount" do
    outgoing, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 900).call

    render_inline(described_class.new(entry: entry_for(outgoing, source: "Default", destination: "Savings")))

    expect(page).to have_link("Transfer: Default → Savings ($ 900)")
  end

  it "falls back when account names are unknown" do
    outgoing, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 900).call

    render_inline(described_class.new(entry: entry_for(outgoing)))

    expect(page).to have_text("Transfer: Default → Unknown account")
  end
end
