class AddImportSourceTable < ActiveRecord::Migration
  def self.up
    create_table "import_sources", :force => true do |t|
      t.column :name, :string
      t.column :adapter, :string
      t.column :host, :string
      t.column :username, :string
      t.column :password, :string
      t.column :database, :string
    end
  end

  def self.down
    drop_table "import_sources"
  end
end
