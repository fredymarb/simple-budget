class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :budget, null: false, foreign_key: { to_table: :budgets }
      t.string :name, null: false

      t.timestamps
    end
  end
end
