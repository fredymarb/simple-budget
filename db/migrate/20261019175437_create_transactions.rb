class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :budget, null: false, foreign_key: { to_table: :budgets }
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.references :category, foreign_key: { to_table: :categories }

      t.date :date, null: false
      t.integer :kind, null: false
      t.bigint :amount_minor, null: false

      t.uuid :transfer_group_id
      t.string :memo

      t.timestamps
    end

    add_index :transactions, :transfer_group_id
  end
end
