class AddRequiredCustomerConfigs < ActiveRecord::Migration
  def self.up
    CustomerConfig.create!(:name => 'smtp', :value => nil, :required => true)
    CustomerConfig.create!(:name => 'protocol', :value => nil, :required => true)
    CustomerConfig.create!(:name => 'host', :value => nil, :required => true)
    CustomerConfig.create!(:name => 'port', :value => nil, :required => true)
    CustomerConfig.create!(:name => 'admin_email', :value => nil, :required => true)
  end

  def self.down
    CustomerConfig.find(:first, :conditions => {:name => 'smtp'}).try(:destroy)
    CustomerConfig.find(:first, :conditions => {:name => 'protocol'}).try(:destroy)
    CustomerConfig.find(:first, :conditions => {:name => 'host'}).try(:destroy)
    CustomerConfig.find(:first, :conditions => {:name => 'port'}).try(:destroy)
    CustomerConfig.find(:first, :conditions => {:name => 'admin_email'}).try(:destroy)
  end
end
