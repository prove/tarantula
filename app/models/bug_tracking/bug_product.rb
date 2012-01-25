=begin rdoc

A bug product.

=end
class BugProduct < ActiveRecord::Base
  belongs_to :bug_tracker
  
  validates_uniqueness_of :external_id, :scope => :bug_tracker_id
  validates_presence_of :bug_tracker_id, :name, :external_id
  has_and_belongs_to_many :projects
  has_many :bugs, :dependent => :destroy
  has_many :bug_components, :dependent => :destroy
  alias_method :components, :bug_components
  
  def self.external_id_scope; :bug_tracker; end
  def deleted; false; end
  
  def to_data
    {:id          => self.id,
     :external_id => self.external_id,
     :name        => self.name}
  end
end
