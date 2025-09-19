class SetDefaultSuspendedToFalse < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :suspended, false
    # Update existing records that have null values
    User.where(suspended: nil).update_all(suspended: false)
  end
end

