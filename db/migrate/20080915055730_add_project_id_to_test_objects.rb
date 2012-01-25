class AddProjectIdToTestObjects < ActiveRecord::Migration
  def self.up
    add_column :test_objects, :project_id, :integer
    
    # --- Data ---
    TestObject.all.each do |to|
      projs = to.executions.map{|e| ts = e.test_set; ts.nil? ? nil : ts.project}.\
        compact.uniq
      to.update_attribute(:project_id, projs.first.id) if projs.size > 0
      if projs.size > 1
        projs[1..-1].each do |p|
          TestObject.create!(:project_id => p.id, :name => to.name)
        end
      end
    end
    
  end

  def self.down
    remove_column :test_objects, :project_id
    # --- No data migrations (model validation dependencies) ---
  end
end
