class CreateRequirements < ActiveRecord::Migration
  def self.up
    create_table :requirements do |t|
      t.string :external_id
      t.string :name
      t.integer :project_id
      t.timestamps
    end
    create_table :cases_requirements, :id => false do |t|
      t.integer :case_id
      t.integer :requirement_id
    end
  end

  def self.down
    drop_table :requirements
    drop_table :cases_requirements
  end
end
