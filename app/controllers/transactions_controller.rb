class TransactionsController < ApplicationController
  before_action :set_budget
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @month = month_param(params[:month])
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
