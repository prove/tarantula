class AddTypeAndDataToAttachments < ActiveRecord::Migration
  def self.up
    add_column :attachments, :type, :string, :default => 'Attachment'
    add_column :attachments, :data, :text
  end

  def self.down
    remove_column :attachments, :type
    remove_column :attachments, :data
  end
  
end
