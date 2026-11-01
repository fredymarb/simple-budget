module Transactions
  # Creates or updates a transaction (income, expense or transfer) from form params.
  class Save
    KINDS = %w[income expense transfer].freeze
    SUBMITTED_KEYS = %i[amount_minor date source_account_id destination_account_id].freeze

    Result = Struct.new(:success, :transaction, :month, :notice, :error, :submitted, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(budget:, params:, transaction: nil)
      @budget = budget
      @params = params
      @transaction = transaction || budget.transactions.new
    end

    def call
      if @transaction.new_record?
        return failure("Select a valid transaction type.") unless KINDS.include?(@params[:kind])

        @transaction.kind = @params[:kind]
      end

      @transaction.transfer? ? save_transfer : save_transaction
    end

    private

    def save_transaction
      assign_attributes
      new_record = @transaction.new_record?

      if @transaction.save
        success(new_record ? "Transaction was successfully created." : "Transaction was successfully updated.")
      else
        failure(nil)
      end
    end

    def assign_attributes
      @transaction.assign_attributes(@params.slice(:amount_minor, :date, :memo))
      @transaction.account = find_account(@params[:account_id])
      @transaction.category = @params[:category_id].present? ? @budget.categories.find_by(id: @params[:category_id]) : nil
    end

    def save_transfer
      source = find_account(@params[:source_account_id])
      destination = find_account(@params[:destination_account_id])

      if @transaction.new_record?
        Transfers::Create.new(
          source_account: source,
          destination_account: destination,
          amount_minor: @params[:amount_minor],
          date: date,
          memo: @params[:memo]
        ).call
        success("Transfer completed successfully.")
      else
        return failure("Both accounts must exist.") unless source && destination

        Transfers::Update.new(
          transaction: @transaction,
          source_account: source,
          destination_account: destination,
          amount_minor: @params[:amount_minor],
          date: date,
          memo: @params[:memo]
        ).call
        success("Transfer was successfully updated.")
      end
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    def find_account(id)
      @budget.accounts.find_by(id: id)
    end

    def date
      Date.iso8601(@params[:date])
    rescue Date::Error, TypeError
      nil
    end

    def month
      (date || @transaction.date)&.strftime("%Y-%m")
    end

    def success(notice)
      Result.new(success: true, transaction: @transaction, month: month, notice: notice)
    end

    def failure(error)
      Result.new(
        success: false,
        transaction: @transaction,
        error: error,
        submitted: @params.slice(*SUBMITTED_KEYS).to_h.symbolize_keys
      )
    end
  end
end
