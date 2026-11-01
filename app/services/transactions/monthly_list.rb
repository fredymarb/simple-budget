module Transactions
  # Transactions of a month grouped by date. Each transfer appears once (as its
  # outgoing leg) with the names of both accounts resolved.
  class MonthlyList
    Entry = Struct.new(:transaction, :source_name, :destination_name) do
      delegate :transfer?, to: :transaction
    end

    def initialize(budget:, month:)
      @budget = budget
      @month = month
    end

    def call
      entries.group_by { |entry| entry.transaction.date }
    end

    private

    def entries
      transfer_accounts = transfer_account_names

      transactions.reject { |transaction| transaction.transfer? && transaction.amount_minor.positive? }.map do |transaction|
        names = transfer_accounts[transaction.transfer_group_id] || {}
        Entry.new(transaction, names[:source], names[:destination])
      end
    end

    def transactions
      @transactions ||= @budget.transactions
        .where(date: @month.beginning_of_month..@month.end_of_month)
        .order(date: :desc, id: :desc)
        .includes(:category, :account)
        .to_a
    end

    def transfer_account_names
      transactions.select(&:transfer?).group_by(&:transfer_group_id).transform_values do |legs|
        {
          source: legs.find { |leg| leg.amount_minor.negative? }&.account&.name,
          destination: legs.find { |leg| leg.amount_minor.positive? }&.account&.name
        }
      end
    end
  end
end
