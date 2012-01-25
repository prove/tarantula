class CreateAttachmentVersioning < ActiveRecord::Migration
  def self.up
    create_table :attachment_sets do |t|
      t.timestamps
      t.integer :host_id
      t.string :host_type
      t.integer :host_version
    end
    
    create_table :attachment_sets_attachments, :id => false do |t|
      t.integer :attachment_set_id
      t.integer :attachment_id
    end
    
  end

  def self.down
    drop_table :attachment_sets
    drop_table :attachment_sets_attachments
  end
end
