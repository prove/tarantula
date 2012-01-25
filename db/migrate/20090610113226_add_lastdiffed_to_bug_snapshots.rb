class AddLastdiffedToBugSnapshots < ActiveRecord::Migration
  def self.up
    add_column :bug_snapshots, :lastdiffed, :time
  end

  def self.down
    remove_column :bug_snapshots, :lastdiffed
  end
end
