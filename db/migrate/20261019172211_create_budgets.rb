class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :currency, null: false

      t.timestamps
    end
  end
end
