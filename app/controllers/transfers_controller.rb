
class TransfersController < ApplicationController
  before_action :set_budget

  def create
    Transfers::Create.new(
      source_account: @budget.accounts.find(params[:source_account_id]),
      destination_account: @budget.accounts.find(params[:destination_account_id]),
      amount_minor: transfer_params[:amount_minor],
      date: transfer_params[:date],
      memo: transfer_params[:memo]
    ).call

    redirect_to accounts_path, notice: "Transfer completed successfully."
  rescue ArgumentError => e
    redirect_to accounts_path, alert: e.message
  end

  def update
    transaction = @budget.transactions.find(params[:id])

    Transfers::Update.new(
      transaction: transaction,
      amount_minor: transfer_params[:amount_minor],
      date: transfer_params[:date],
      memo: transfer_params[:memo]
    ).call

    redirect_to accounts_path, notice: "Transfer updated successfully."
  rescue ArgumentError => e
    redirect_to accounts_path, alert: e.message
  end

  def destroy
    transaction = @budget.transactions.find(params[:id])

    Transfers::Destroy.new(transaction: transaction).call

    redirect_to accounts_path, notice: "Transfer deleted successfully."
  rescue ArgumentError => e
    redirect_to accounts_path, alert: e.message
  end

  private

  def transfer_params
    params.require(:transfer).permit(
      :source_account_id,
      :destination_account_id,
      :amount_minor,
      :date,
      :memo
    )
  end
end
