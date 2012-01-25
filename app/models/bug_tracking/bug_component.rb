=begin rdoc

A bug component.

=end
class BugComponent < ActiveRecord::Base
  validates_presence_of :name, :bug_product_id
  validates_uniqueness_of :external_id, :scope => :bug_product_id
  
  belongs_to :bug_product
  alias_method :product, :bug_product
  
  has_many :bugs
  
  alias_attribute :product, :bug_product
  
  def self.external_id_scope; :bug_product; end
  def deleted; false; end
end
