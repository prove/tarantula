=begin rdoc

A test area.

=end
class TestArea < ActiveRecord::Base
  validates_presence_of :name, :project_id
  validates_uniqueness_of :name, :case_sensitive => false,
                          :scope => :project_id

  validates_format_of :name, :with => /^[^,]+$/
  belongs_to :project
  scope :ordered, order('name ASC')

  has_and_belongs_to_many :requirements, :select => 'requirements.*'
  has_and_belongs_to_many :test_sets, :select => 'test_sets.*'
  has_and_belongs_to_many :cases, :select => 'cases.*'
  has_and_belongs_to_many :executions, :select => 'executions.*'
  has_and_belongs_to_many :test_objects, :select => 'test_objects.*'

  has_and_belongs_to_many :bug_products

  # Convenience accessor if test area is forced to user via project
  # assignment
  attr_accessor :forced

  def to_data
    { :id => self.id,
      :name => self.name,
      :bug_products => self.bug_products.map(&:to_data) }
  end

  def to_tree
    { :text => self.name,
      :dbid => self.id,
      :leaf => false,
      :cls => 'folder x-listpanel-tag' }
  end

  # latest test object with run case executions in this area
  def current_test_object
    execs = self.executions
    return nil if execs.empty?
    TestObject.ordered.find(:first,
                            :joins => :executions,
                            :conditions => {'executions.id' => execs.map(&:id)})
  end

end
