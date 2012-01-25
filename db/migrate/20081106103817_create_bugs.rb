class CreateBugs < ActiveRecord::Migration
  def self.up
    create_table :bugs do |t|
      t.integer :bug_tracker_id
      t.integer :bug_severity_id
      t.string :external_id
      t.string :summary
      t.timestamps
    end
    
    create_table :bug_severities do |t|
      t.integer :bug_tracker_id
      t.string :name
      t.string :sortkey
    end
    
    create_table :bug_trackers do |t|
      t.string :name
      t.string :bug_post_url
      t.string :db_host
      t.string :db_port
      t.string :db_name
      t.string :db_user
      t.string :db_passwd
    end
    
    create_table :bug_tracker_configs do |t|
      t.integer :project_id
      t.integer :bug_tracker_id
      t.string :product_ids
    end
    
    add_column :step_executions, :bug_id, :integer
  end

  def self.down
    drop_table :bugs
    drop_table :bug_severities
    drop_table :bug_trackers
    drop_table :bug_tracker_configs
    
    remove_column :step_executions, :bug_id    
  end
end
