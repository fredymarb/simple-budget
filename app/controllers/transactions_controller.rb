class TransactionsController < ApplicationController
  before_action :set_budget
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @month = parse_month_param(params[:month])
    @transactions_by_date = Transactions::MonthlyList.new(budget: @budget, month: @month).call
  end

  def show
  end

  def new
    @form_state = form_state(@budget.transactions.new(kind: :expense, date: Date.current))
  end

  def create
    save(@budget.transactions.new, template: :new)
  end

  def edit
    @form_state = form_state(@transaction)
  end

  def update
    save(@transaction, template: :edit)
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

  def save(transaction, template:)
    result = Transactions::Save.new(budget: @budget, params: transaction_params, transaction: transaction).call

    if result.success?
      redirect_to transactions_path(month: result.month), notice: result.notice
    else
      @form_state = form_state(result.transaction, error: result.error, submitted: result.submitted)
      render template, status: :unprocessable_content
    end
  end

  def form_state(transaction, **options)
    Transactions::FormState.new(budget: @budget, transaction: transaction, **options)
  end
end
