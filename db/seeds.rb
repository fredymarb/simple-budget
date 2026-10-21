# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

admin = User.find_by(email: "admin@example.com")
budget = Budget.find_by(user: admin)
account = budget.accounts.first!

transactions = [
  { account: account, category_id: 12, kind: "income", amount_minor: 500_000, date: Date.today },
  { account: account, category_id: 12, kind: "income", amount_minor: 200_000, date: Date.today },
  { account: account, category_id: 11, kind: "expense", amount_minor: -150_000, date: Date.today },
  { account: account, category_id: 2, kind: "expense", amount_minor: -50_000, date: Date.today }
]

transactions.each do |transaction_attrs|
  budget.transactions.find_or_create_by!(transaction_attrs)
end
