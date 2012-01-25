class RenameOrderColumn < ActiveRecord::Migration
  def self.up
    # Naming column as order causes too much trouble, because it's
    # reserved word in sql. (even though it could be escaped)
    rename_column :cases_test_sets, :order, :position
  end

  def self.down
    rename_column :cases_test_sets, :position, :order
  end
end
