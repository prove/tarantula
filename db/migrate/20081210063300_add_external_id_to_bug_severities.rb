class AddExternalIdToBugSeverities < ActiveRecord::Migration
  def self.up
    add_column :bug_severities, :external_id, :string
  end

  def self.down
    remove_column :bug_severities, :external_id
  end
end
