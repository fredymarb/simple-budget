module Transfers
  class Destroy
    def initialize(transaction:)
      @transaction = transaction
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        transactions = Transaction.where(
          transfer_group_id: @transaction.transfer_group_id,
          budget_id: @transaction.budget_id,
          kind: :transfer
        )

        transactions.destroy_all
      end
    end

    private

    def validate!
      unless @transaction.persisted? && @transaction.transfer?
        raise ArgumentError, "Transaction must be a persisted transfer"
      end

      unless @transaction.transfer_group_id.present?
        raise ArgumentError, "Transfer must have a transfer group ID"
      end
    end
  end
end
