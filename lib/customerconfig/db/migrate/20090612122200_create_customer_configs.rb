class CreateCustomerConfigs < ActiveRecord::Migration
  def self.up
    create_table :customer_configs do |t|
      t.string :name
      t.text :value
      t.boolean :required
      t.timestamps
    end
  end
  
  def self.down
    drop_table :customer_configs
  end
end
