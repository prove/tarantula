class RemoveGuestPermissions < ActiveRecord::Migration
  def self.up
    ProjectAssignment.destroy_all({:group => 'GUEST'})
  end

  def self.down
  end
end
