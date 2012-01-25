class CreateTestObjects < ActiveRecord::Migration
  def self.up 
    create_table :test_objects do |t|
      t.string :name
      t.timestamps
    end
    
    add_column :executions, :test_object_id, :integer
    
    # --- Data ---
    tos = select_all "SELECT id, test_object FROM executions"
    
    tos.each do |to|
      e = Execution.find(to['id'].to_i)
      name = to['test_object']
      name = 'unknown' if name.blank? or name.length == 0
      test_ob = TestObject.find_by_name(name)

      if test_ob.nil?
        test_ob = TestObject.create!(:name => name)
      end
      e.test_object = test_ob
      e.save!
    end
    
    # ---
    remove_column :executions, :test_object
  end

  def self.down
    add_column :executions, :test_object, :string
    remove_column :executions, :test_object_id
    # --- Data ---
    # Data lost here. Validations will fail also (presence of test_object_id).
    # ---
    
    drop_table :test_objects
  end
end
