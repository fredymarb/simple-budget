module Budgets
  class CreateDefault
    CATEGORY_NAMES = [
      "Eating Out", "Groceries", "Entertainment", "E-cash",
      "Gift", "Grooming", "Gym", "Internet", "Miscellaneous",
      "Phone", "Rent", "Salary", "Savings", "Transport", "Utilities"
    ].freeze

    def initialize(user:)
      @user = user
    end

    def self.call(user:)
      new(user: user).call
    end

    def call
      ActiveRecord::Base.transaction do
        budget = user.create_budget!(
          name: "My Budget",
          currency: "USD"
        )

        account = budget.accounts.create!(name: "Default")

        create_categories(budget)
        categories = budget.categories.index_by(&:name)

        # TODO: Remove dummy transactions creation in production environment
        create_dummy_transactions(budget, account, categories)

        budget
      end
    end

    private

    attr_reader :user

    def create_categories(budget)
      now = Time.current

      rows = CATEGORY_NAMES.map do |name|
        {
          budget_id: budget.id,
          name: name,
          created_at: now,
          updated_at: now
        }
      end

      Category.insert_all!(rows)
    end

    def create_dummy_transactions(budget, account, categories)
      today = Date.current

      transactions = [
        {
          account: account,
          kind: "income",
          amount_minor: 100_000,
          date: today,
          category: categories.fetch("Salary"),
          memo: "Monthly salary"
        },
        {
          account: account,
          kind: "expense",
          amount_minor: -40_000,
          date: today,
          category: categories.fetch("Rent"),
          memo: "Monthly rent"
        },
        {
          account: account,
          kind: "expense",
          amount_minor: -20_000,
          date: today,
          category: categories.fetch("Groceries"),
          memo: "Weekly groceries"
        }
      ]

      budget.transactions.create!(transactions)
    end
  end
end
