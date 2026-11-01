# frozen_string_literal: true

class TransactionFormComponent < ViewComponent::Base
  KIND_OPTIONS = [ [ "Income", "income" ], [ "Expense", "expense" ], [ "Transfer", "transfer" ] ].freeze

  attr_reader :state

  delegate :transaction, :accounts, :categories, :error, to: :state

  def initialize(state:)
    @state = state
  end

  def submit_label
    transaction.new_record? ? "Create Transaction" : "Update Transaction"
  end

  def kind_options
    KIND_OPTIONS
  end

  def transfer?
    transaction.transfer?
  end
end
