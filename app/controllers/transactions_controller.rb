class TransactionsController < ApplicationController
  before_action :set_budget
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @month = parse_month_param(params[:month])
    @monthly_transactions = @budget
      .transactions
      .where(date: @month.beginning_of_month..@month.end_of_month)
      .order(date: :desc, id: :desc)
      .includes(:category)
  end

  def show
  end

  def new
    @transaction = @budget.transactions.new
    @accounts = @budget.accounts
    @categories = @budget.categories
  end

  def create
    @transaction = @budget.transactions.new(transaction_params)
    @month = parse_month_param(params[:month])
    if @transaction.save
      redirect_to transactions_path(month: @month), notice: "Transaction was successfully created."
    else
      @accounts = @budget.accounts
      @categories = @budget.categories
      render :new
    end
  end

  def edit
    @accounts = @budget.accounts
    @categories = @budget.categories
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to transactions_path(month: @month), notice: "Transaction was successfully updated."
    else
      @accounts = @budget.accounts
      @categories = @budget.categories
      render :edit
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path(month: @month), notice: "Transaction was successfully deleted."
  end

  private

  def set_transaction
    @transaction = @budget.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction)
      .permit(:amount_minor, :kind, :date, :memo, :account_id, :category_id)
  end
end
