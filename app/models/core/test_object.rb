=begin rdoc

Test object. Reflects a testable configuration, e.g. a version of a software.

==Attributes
::name      Name of test object

=end
class TestObject < ActiveRecord::Base
  include AttachingExtensions
  include TaggingExtensions
  
  has_many :executions, :dependent => :destroy
  belongs_to :project
  has_and_belongs_to_many :test_areas
  validates_length_of :name, :minimum => 1
  validates_uniqueness_of :name, :scope => :project_id
  validates_presence_of :project_id, :date
  
  # default ordering
  scope :ordered, 
              order('test_objects.date DESC, test_objects.created_at DESC')
  
  scope :active, where(:deleted => 0, :archived => 0).order('date desc')
  
  scope :deleted, where(:deleted => 1).order('date desc')

  # Return project's requirements for this test object.
  # Revert requirements to their last version which is applicable to 
  # this test_object, i.e. which was not updated after self.date
  def requirements
    reqs = self.project.requirements.active.find(:all, 
      :conditions => "date <= '#{self.date}'")
    reqs.each do |req|
      versions = req.versions
      vers = versions.reverse.detect{|rv| rv.updated_at.to_date <= self.date}
      req.revert_to(vers.version) if vers
    end
    reqs
  end
  
  def self.create_with_tags(atts, tag_list=nil)
    to = nil
    transaction do
      to = self.create!(atts)
      to.tag_with(tag_list) unless tag_list.blank?
    end
    to
  end
  
  def update_with_tags(atts, tag_list=nil)
    transaction do
      self.update_attributes!(atts)
      self.tag_with(tag_list || "")
    end
  end
  
  def to_data
    { :name => self.name,
      :id => self.id,
      :date => self.date,
      :esw => self.esw,
      :swa => self.swa,
      :hardware => self.hardware,
      :mechanics => self.mechanics,
      :description => self.description,
      :deleted => self.deleted,
      :archived => self.archived,
      :tag_list => self.tags_to_s,
      :test_area_ids => self.test_area_ids }
  end
  
  def to_tree
    {
      :text => self.name,
      :dbid => self.id,
      :cls => 'x-listpanel-item',
      :deleted => self.deleted,
      :archived => self.archived,
      :tags => self.tags_to_s
    }
  end
  
  def to_s
    "#{self.name}"
  end
  
  def self.find_by_dates(proj_id, sdate, edate, only_active=true)
    conds = ['DATE(executed_at) >= :sdate and DATE(executed_at) <= :edate and '+
             'test_objects.project_id = :pid', 
             {:sdate => sdate, :edate => edate, :pid => proj_id}]
    
    if only_active
      conds[0] += " and result != :res"
      conds[1].merge!({:res => NotRun.db})
    end
    
    TestObject.ordered.where(conds).select('distinct test_objects.*').
      joins(:executions => :case_executions)
  end
  
  def self.active_date_range(test_objects)
    conds = ["test_objects.id in (:tobs) and result != :re", 
            {:re => NotRun.db, :tobs => test_objects.map(&:id)}]
    start_ce = CaseExecution.joins(:execution => :test_object).where(conds).
      order('executed_at asc').first
    end_ce = CaseExecution.joins(:execution => :test_object).where(conds).
      order('executed_at desc').first
    sday = (start_ce ? start_ce.executed_at.to_date : nil)
    eday = (end_ce ? end_ce.executed_at.to_date : nil)
    return nil if !sday or !eday
    sday..eday
  end
  
end
