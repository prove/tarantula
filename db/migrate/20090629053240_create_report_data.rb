class CreateReportData < ActiveRecord::Migration
  def self.up
    create_table :report_data do |t|
      t.string :key
      t.integer :project_id
      t.integer :user_id
      t.text :data
      t.timestamps
    end
  end
  
  def self.down
    drop_table :report_data
  end
end
