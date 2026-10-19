class BudgetsController < ApplicationController
  before_action :set_budget, only: [ :show ]

  def show
    @month = month_param(params[:month])
  end

  private

  def month_param(value)
    Date.strptime("#{value}-01", "%Y-%m")
  rescue ArgumentError, TypeError
    Date.today.beginning_of_month
  end

  def set_budget
    @budget = current_user.budget
  end

  def budget_params
    params.require(:budget).permit(:month)
  end
end
