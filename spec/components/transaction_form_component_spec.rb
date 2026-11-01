require "rails_helper"

RSpec.describe TransactionFormComponent, type: :component do
  let(:budget) { create(:user).budget }
  let(:checking) { budget.accounts.first }
  let(:savings) { create(:account, budget: budget, name: "Savings") }

  def render_form(transaction, **options)
    state = Transactions::FormState.new(budget: budget, transaction: transaction, **options)
    render_inline(described_class.new(state: state))
  end

  it "offers a kind selector and 'Create' for a new transaction" do
    render_form(budget.transactions.new(kind: :expense, date: Date.current))

    expect(page).to have_select("Type", options: %w[Income Expense Transfer])
    expect(page).to have_field("Amount", type: "text", placeholder: "0.00")
    expect(page).to have_css('input[name="transaction[amount]"][inputmode="decimal"]')
    expect(page).to have_button("Create Transaction")
    expect(page).to have_css("[data-controller='transaction-form']")
  end

  it "lists the budget's accounts and categories" do
    render_form(budget.transactions.new(kind: :expense, date: Date.current))

    expect(page).to have_select("Account", with_options: [ "Default" ])
    expect(page).to have_select("Category", with_options: [ "Salary", "Rent" ])
  end

  it "fixes the kind and says 'Update' for an existing transaction" do
    render_form(budget.transactions.find_by!(memo: "Monthly rent"))

    expect(page).to have_text("Type: Expense")
    expect(page).to have_no_select("Type")
    expect(page).to have_button("Update Transaction")
  end

  it "shows the form error and validation messages" do
    transaction = budget.transactions.new(kind: :income, date: Date.current)
    transaction.validate

    render_form(transaction, error: "Something went wrong")

    expect(page).to have_css("[role=alert]", text: "Something went wrong")
    expect(page).to have_text("Category can't be blank")
  end

  it "preselects both accounts of an existing transfer" do
    outgoing, = Transfers::Create.new(source_account: checking, destination_account: savings, amount_minor: 800).call

    render_form(outgoing)

    expect(page).to have_field("From account", with: checking.id.to_s)
    expect(page).to have_field("To account", with: savings.id.to_s)
    expect(page).to have_field(
      "Amount",
      with: Money.minor_to_decimal(800, exponent: Money::EXPONENTS[budget.currency])
    )
  end
end
