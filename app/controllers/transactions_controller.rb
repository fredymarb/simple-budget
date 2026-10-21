class TransactionsController < ApplicationController
  before_action :set_budget
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @month = month_params(params[:month])
    @transactions = @budget.transactions
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
    if @transaction.save
      redirect_to transactions_path
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
      redirect_to transactions_path(@budget)
    else
      @accounts = @budget.accounts
      @categories = @budget.categories
      render :edit
    end
  end

  def destroy
    @transaction.destroy
    redirect_to budget_transactions_path(@budget)
  end

  private

  def month_params
    Date.strptime(params[:month], "%Y-%m")
  rescue ArgumentError, TypeError
    Date.today.beginning_of_month
  end

  def set_budget
    @budget = current_user.budget
  end

  def set_transaction
    @transaction = @budget.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction)
      .permit(:month, :amount_minor, :kind, :date, :memo, :transfer_group_id, :account_id, :category_id)
  end
end
