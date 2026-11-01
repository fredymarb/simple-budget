# frozen_string_literal: true

class TransactionListItemComponent < ViewComponent::Base
  with_collection_parameter :entry

  attr_reader :entry

  delegate :transaction, to: :entry

  def initialize(entry:)
    @entry = entry
  end

  def transfer?
    entry.transfer?
  end

  def label
    if transfer?
      "Transfer: #{entry.source_name || transaction.account.name} → #{entry.destination_name || 'Unknown account'}"
    else
      transaction.category.name
    end
  end

  def amount
    helpers.display_money(transfer? ? transaction.amount_minor.abs : transaction.amount_minor)
  end
end
