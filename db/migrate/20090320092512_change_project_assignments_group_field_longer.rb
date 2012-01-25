class ChangeProjectAssignmentsGroupFieldLonger < ActiveRecord::Migration
  def self.up
    change_column :project_assignments, :group, :string
  end

  def self.down
  end
end
