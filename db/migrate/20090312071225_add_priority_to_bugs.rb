class AddPriorityToBugs < ActiveRecord::Migration
  def self.up
    add_column :bugs, :priority, :string
  end
  
  def self.down
    remove_column :bugs, :priority
  end
  
end
