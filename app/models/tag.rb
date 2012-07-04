=begin rdoc

A tag.

=end
class Tag < ActiveRecord::Base

  validates_presence_of :name, :project_id
  validates_uniqueness_of :name, :case_sensitive => false,
                          :scope => [:project_id, :taggable_type]
  
  validates_format_of :name, :with => /^[^,]+$/,
  :message => "Comma is not allowed in tag name."
  has_many :taggings, :dependent => :destroy
  belongs_to :project
  
  scope :ordered, order('name ASC')
  
  # used in application controller
  class Error < StandardError
  end
  
  def self.find_for_project_and_class(p, klass, selected, test_area=nil, 
                                      extra_conditions=[],
                                      extra_joins=[])
    return [] if %w(deleted archived).include?(selected)
    
    klass_table = klass.to_s.tableize
    
    conds = ["#{klass_table}.deleted=0 AND #{klass_table}.archived=0"] + 
            extra_conditions
    
    selected ||= []
    selected.each do |tag|
      conds << "exists (select id from taggings where taggable_type="+
               "'#{klass}' and taggable_id=#{klass_table}.id and "+
               "tag_id=#{tag.id})"
    end
    
    resource_ids = (test_area || p).send(klass_table).find(
      :all, 
      :joins => (["JOIN taggings ON taggings.taggable_type='#{klass}' and taggings.taggable_id=#{klass_table}.id"]+
                extra_joins).join(' '), 
      :conditions => conds.join(' AND '),
      :select => "#{klass_table}.id")
    
    tags = Tag.ordered.find(:all, :joins => :taggings, :select => 'distinct tags.*',
      :conditions => [
      'taggings.taggable_id in (:tids) and taggings.taggable_type=:tt and '+
      'tags.project_id=:pid and tags.taggable_type=:tt',
      {:tids => resource_ids, 
       :tt   => klass.to_s,
       :pid  => p}])
    
    tags - selected
  end
  
  def to_tree
    { :text => self.name,
      :dbid => self.id,
      :leaf => false,
      :cls => 'folder x-listpanel-tag' }
  end
  
end
