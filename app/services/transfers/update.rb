module Transfers
  class Update
    def initialize(transaction:, amount_minor:, date:, memo: nil, source_account: nil, destination_account: nil)
      @transaction = transaction
      @amount_minor = parse_amount_minor(amount_minor)
      @date = parse_date(date)
      @memo = memo
      @source_account = source_account
      @destination_account = destination_account
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        outgoing_transaction.update!(
          account: @source_account,
          amount_minor: -@amount_minor,
          date: @date,
          memo: @memo
        )
        incoming_transaction.update!(
          account: @destination_account,
          amount_minor: @amount_minor,
          date: @date,
          memo: @memo
        )
      end

      transfer_transactions
    end

    private

    def transfer_transactions
      @transfer_transactions ||= Transaction
        .where(
          budget_id: @transaction.budget_id,
          transfer_group_id: @transaction.transfer_group_id,
          kind: :transfer
        )
        .order(:id)
        .to_a
    end

    def outgoing_transaction
      transfer_transactions.find { |transaction| transaction.amount_minor.negative? }
    end

    def incoming_transaction
      transfer_transactions.find { |transaction| transaction.amount_minor.positive? }
    end

    def validate!
      unless @transaction.persisted? && @transaction.transfer?
        raise ArgumentError, "Transaction must be a persisted transfer"
      end

      unless @transaction.transfer_group_id.present?
        raise ArgumentError, "Transfer must have a transfer group ID"
      end

      unless transfer_transactions.size == 2 &&
             transfer_transactions.count { |t| t.amount_minor.negative? } == 1 &&
             transfer_transactions.count { |t| t.amount_minor.positive? } == 1
        raise ArgumentError, "Transfer must have exactly two valid transaction records"
      end

      @source_account ||= outgoing_transaction.account
      @destination_account ||= incoming_transaction.account

      unless @source_account&.persisted? && @destination_account&.persisted?
        raise ArgumentError, "Both accounts must exist"
      end

      if @source_account.id == @destination_account.id
        raise ArgumentError, "Source and destination accounts must differ"
      end

      unless [ @source_account, @destination_account ].all? { |account| account.budget_id == @transaction.budget_id }
        raise ArgumentError, "Accounts must belong to the same budget"
      end

      unless @amount_minor.positive?
        raise ArgumentError, "Transfer amount must be positive"
      end

      unless @date.is_a?(Date)
        raise ArgumentError, "Transfer date must be a date"
      end
    end

    def parse_amount_minor(value)
      case value
      when Integer
        value
      when String
        Integer(value, 10)
      else
        raise ArgumentError
      end
    rescue ArgumentError, TypeError
      raise ArgumentError, "Amount must be an integer in minor units"
    end

    def parse_date(value)
      return value if value.is_a?(Date)

      Date.iso8601(value)
    rescue Date::Error, TypeError
      nil
    end
  end
end
