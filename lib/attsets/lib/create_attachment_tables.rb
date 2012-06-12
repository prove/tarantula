class CreateAttachmentTables < ActiveRecord::Migration
  def self.up
    create_table "attachment_sets", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "host_id"
      t.string   "host_type"
      t.integer  "host_version"
    end
    
    create_table "attachment_sets_attachments", :id => false, :force => true do |t|
      t.integer "attachment_set_id"
      t.integer "attachment_id"
    end

    create_table "attachments", :force => true do |t|
      t.string   "orig_filename"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "type",          :default => "Attachment"
      t.text     "data"
    end
  end
  
  def self.down
    drop_table "attachment_sets"
    
    drop_table "attachment_sets_attachments"

    drop_table "attachments"
  end
end