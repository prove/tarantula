class MakeRequirementsVersioned < ActiveRecord::Migration
  def self.up
    create_table :requirement_versions do |t|
      t.integer :requirement_id
      t.integer :version
      t.timestamps
      t.string :external_id
      t.string :name
      t.integer :project_id
      t.integer :created_by
      t.date :date
      t.boolean :deleted
      t.date :external_modified_on
      t.text :description
      t.string :priority
      t.text :optionals
    end
    add_column :cases_requirements, :case_version, :integer
    add_column :cases_requirements, :requirement_version, :integer
    add_column :requirements, :version, :integer, :default => 1
    execute "update cases_requirements set case_version=1"
    execute "update cases_requirements set requirement_version=1"
  end

  def self.down
    drop_table :requirement_versions
    remove_column :cases_requirements, :case_version
    remove_column :cases_requirements, :requirement_version
    remove_column :requirements, :version
  end
end
