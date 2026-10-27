require "securerandom"

module Transfers
  class Create
    def initialize(source_account:, destination_account:, amount_minor:, date: Date.current, memo: nil)
      @source_account = source_account
      @destination_account = destination_account
      @amount_minor = parse_amount_minor(amount_minor)
      @date = date
      @memo = memo
    end

    def call
      validate!

      transfer_group_id = SecureRandom.uuid

      ActiveRecord::Base.transaction do
        outgoing_transaction = @source_account.transactions.create!(
          budget_id: @source_account.budget_id,
          date: @date,
          kind: :transfer,
          amount_minor: -@amount_minor,
          transfer_group_id: transfer_group_id,
          memo: @memo
        )

        incoming_transaction = @destination_account.transactions.create!(
          budget_id: @destination_account.budget_id,
          date: @date,
          kind: :transfer,
          amount_minor: @amount_minor,
          transfer_group_id: transfer_group_id,
          memo: @memo
        )

        [ outgoing_transaction, incoming_transaction ]
      end
    end

    private

    def validate!
      unless @source_account&.persisted? &&
             @destination_account&.persisted?
        raise ArgumentError, "Both accounts must exist"
      end

      if @source_account.id == @destination_account.id
        raise ArgumentError, "Source and destination accounts must differ"
      end

      if @source_account.budget_id != @destination_account.budget_id
        raise ArgumentError, "Accounts must belong to the same budget"
      end

      unless @amount_minor.positive?
        raise ArgumentError, "Transfer amount must be positive"
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
  end
end
