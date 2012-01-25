class CreateTestAreaAssociations < ActiveRecord::Migration
  def self.up
    create_table :requirements_test_areas, :id => false do |t|
      t.integer :requirement_id
      t.integer :test_area_id
    end
    
    create_table :test_areas_test_sets, :id => false do |t|
      t.integer :test_set_id
      t.integer :test_area_id
    end
    
    create_table :cases_test_areas, :id => false do |t|
      t.integer :case_id
      t.integer :test_area_id
    end
    
    create_table :executions_test_areas, :id => false do |t|
      t.integer :execution_id
      t.integer :test_area_id
    end
    
    create_table :test_areas_test_objects, :id => false do |t|
      t.integer :test_object_id
      t.integer :test_area_id
    end
  end

  def self.down
    drop_table :requirements_test_areas
    drop_table :test_areas_test_sets
    drop_table :cases_test_areas
    drop_table :executions_test_areas
    drop_table :test_areas_test_objects
  end
end
