class CreateSteps < ActiveRecord::Migration
  def self.up
    create_table :steps do |t|
      t.column :case_id, :integer
      t.column :action, :text
      t.column :result, :text
    end
  end

  def self.down
    drop_table :steps
  end
end
