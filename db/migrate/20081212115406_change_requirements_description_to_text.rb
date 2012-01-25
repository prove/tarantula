class ChangeRequirementsDescriptionToText < ActiveRecord::Migration
  def self.up
    change_column :requirements, :description, :text
  end

  def self.down
    change_column :requirements, :description, :string
  end
end
