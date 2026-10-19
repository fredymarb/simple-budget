class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :budget, null: false, foreign_key: { to_table: :budgets }
      t.string :name, null: false

      t.timestamps
    end

    add_index :categories, [ :budget_id, :name ], unique: true
  end
end
