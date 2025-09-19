class AddSuspendedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :suspended, :boolean
  end
end
