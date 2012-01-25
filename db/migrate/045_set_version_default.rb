class SetVersionDefault < ActiveRecord::Migration
  def self.up
    change_column_default :steps, :version, 0
  end

  def self.down
    change_column_default :steps, :version, nil
  end
end
