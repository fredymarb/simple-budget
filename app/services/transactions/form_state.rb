module Transactions
  # Everything the transaction form needs to render, including values to
  # redisplay after a failed submission.
  class FormState
    attr_reader :transaction

    def initialize(budget:, transaction:, error: nil, submitted: {})
      @budget = budget
      @transaction = transaction
      @error = error
      @submitted = submitted || {}
    end

    def accounts
      @accounts ||= @budget.accounts.order(:name)
    end

    def categories
      @categories ||= @budget.categories.order(:name)
    end

    def amount_value
      return @submitted[:amount] if @submitted.key?(:amount)
      return unless transaction.persisted?

      Money.minor_to_decimal(transaction.amount_minor.abs, exponent: Money::EXPONENTS[@budget.currency])
    end

    def date_value
      @submitted[:date] || transaction.date
    end

    def source_account_id
      @submitted.fetch(:source_account_id) { transfer_pair[:source]&.account_id }
    end

    def destination_account_id
      @submitted.fetch(:destination_account_id) { transfer_pair[:destination]&.account_id }
    end

    def error
      @error || incomplete_transfer_error
    end

    private

    def transfer_pair
      @transfer_pair ||= load_transfer_pair
    end

    def load_transfer_pair
      return {} unless transaction.persisted? && transaction.transfer?

      legs = @budget.transactions.where(transfer_group_id: transaction.transfer_group_id, kind: :transfer)
      {
        source: legs.find { |leg| leg.amount_minor.negative? },
        destination: legs.find { |leg| leg.amount_minor.positive? }
      }
    end

    def incomplete_transfer_error
      return unless @submitted.empty? && transaction.persisted? && transaction.transfer?

      "This transfer is incomplete and cannot be edited." unless transfer_pair[:source] && transfer_pair[:destination]
    end
  end
end
