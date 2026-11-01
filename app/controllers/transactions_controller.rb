class TransactionsController < ApplicationController
  before_action :set_budget
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @month = parse_month_param(params[:month])
    transactions = @budget
      .transactions
      .where(date: @month.beginning_of_month..@month.end_of_month)
      .order(date: :desc, id: :desc)
      .includes(:category, :account)

    @transfer_accounts = transactions.select(&:transfer?).group_by(&:transfer_group_id).transform_values do |group|
      {
        source: group.find { |transaction| transaction.amount_minor.negative? }&.account&.name,
        destination: group.find { |transaction| transaction.amount_minor.positive? }&.account&.name
      }
    end
    @monthly_transactions = transactions.reject do |transaction|
      transaction.transfer? && transaction.amount_minor.positive?
    end
  end

  def show
  end

  def new
    @transaction = @budget.transactions.new(kind: :expense, date: Date.current)
    prepare_form
  end

  def create
    @transaction = @budget.transactions.new
    @month = parse_month_param(params[:month])
    attributes = transaction_params

    unless %w[income expense transfer].include?(attributes[:kind])
      @form_error = "Select a valid transaction type."
      prepare_form
      render :new, status: :unprocessable_content
    else
      @transaction.kind = attributes[:kind]
      if @transaction.transfer?
        create_transfer(attributes)
      else
        assign_transaction_attributes(attributes)
        if @transaction.save
          redirect_to transactions_path(month: @transaction.date.strftime("%Y-%m")), notice: "Transaction was successfully created."
        else
          prepare_form
          render :new, status: :unprocessable_content
        end
      end
    end
  end

  def edit
    prepare_form
    if @transaction.transfer?
      transfer_pair = @budget.transactions.where(
        transfer_group_id: @transaction.transfer_group_id,
        kind: :transfer
      ).includes(:account)
      outgoing = transfer_pair.find { |transaction| transaction.amount_minor.negative? }
      incoming = transfer_pair.find { |transaction| transaction.amount_minor.positive? }
      @transfer_source_account_id = outgoing&.account_id
      @transfer_destination_account_id = incoming&.account_id
      @form_error = "This transfer is incomplete and cannot be edited." unless outgoing && incoming
    end
  end

  def update
    if @transaction.transfer?
      update_transfer(transaction_params)
    else
      assign_transaction_attributes(transaction_params)
      if @transaction.save
        redirect_to transactions_path(month: @transaction.date.strftime("%Y-%m")), notice: "Transaction was successfully updated."
      else
        prepare_form
        render :edit, status: :unprocessable_content
      end
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path(month: params[:month]), notice: "Transaction was successfully deleted."
  end

  private

  def set_transaction
    @transaction = @budget.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction)
      .permit(:amount_minor, :kind, :date, :memo, :account_id, :category_id, :source_account_id, :destination_account_id)
  end

  def prepare_form
    @accounts = @budget.accounts.order(:name)
    @categories = @budget.categories.order(:name)
    unless @transfer_fields_submitted
      @transfer_source_account_id ||= @transaction.account_id if @transaction.transfer? && @transaction.amount_minor&.negative?
      @transfer_destination_account_id ||= @transaction.account_id if @transaction.transfer? && @transaction.amount_minor&.positive?
    end
  end

  def assign_transaction_attributes(attributes)
    @transaction.assign_attributes(attributes.except(:account_id, :category_id, :kind))
    @transaction.account = @budget.accounts.find_by(id: attributes[:account_id])
    @transaction.category = attributes[:category_id].present? ? @budget.categories.find_by(id: attributes[:category_id]) : nil
  end

  def create_transfer(attributes)
    @transfer_fields_submitted = true
    @transfer_source_account_id = attributes[:source_account_id]
    @transfer_destination_account_id = attributes[:destination_account_id]
    @form_amount_value = attributes[:amount_minor]
    @form_date_value = attributes[:date]

    Transfers::Create.new(
      source_account: @budget.accounts.find_by(id: attributes[:source_account_id]),
      destination_account: @budget.accounts.find_by(id: attributes[:destination_account_id]),
      amount_minor: attributes[:amount_minor],
      date: transfer_date(attributes[:date]),
      memo: attributes[:memo]
    ).call

    redirect_to transactions_path(month: attributes[:date].to_s.first(7)), notice: "Transfer completed successfully."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    @form_error = e.message
    prepare_form
    render :new, status: :unprocessable_content
  end

  def update_transfer(attributes)
    @transfer_fields_submitted = true
    @transfer_source_account_id = attributes[:source_account_id]
    @transfer_destination_account_id = attributes[:destination_account_id]
    @form_amount_value = attributes[:amount_minor]
    @form_date_value = attributes[:date]

    source_account = @budget.accounts.find_by(id: attributes[:source_account_id])
    destination_account = @budget.accounts.find_by(id: attributes[:destination_account_id])
    unless source_account && destination_account
      @form_error = "Both accounts must exist."
      prepare_form
      render :edit, status: :unprocessable_content
      return
    end

    Transfers::Update.new(
      transaction: @transaction,
      source_account: source_account,
      destination_account: destination_account,
      amount_minor: attributes[:amount_minor],
      date: transfer_date(attributes[:date]),
      memo: attributes[:memo]
    ).call

    redirect_to transactions_path(month: attributes[:date].to_s.first(7)), notice: "Transfer was successfully updated."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    @form_error = e.message
    prepare_form
    render :edit, status: :unprocessable_content
  end

  def transfer_date(value)
    Date.iso8601(value)
  rescue Date::Error, TypeError
    nil
  end
end
