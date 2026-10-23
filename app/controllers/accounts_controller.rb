class AccountsController < ApplicationController
  before_action :set_budget
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = @budget.accounts
  end

  def show
  end

  def new
    @account = @budget.accounts.new
  end

  def create
    @account = @budget.accounts.new(account_params)
    if @account.save
      redirect_to accounts_path, notice: "Account was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to accounts_path, notice: "Account was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @account.destroy
    redirect_to accounts_path, notice: "Account was successfully destroyed."
  end

  private

  def set_budget
    @budget = current_user.budget
  end

  def set_account
    @account = @budget.accounts.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name)
  end
end
