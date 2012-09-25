=begin rdoc

A set of cases planned to be executed as a set.

=end
class TestSet < ActiveRecord::Base
  include TaggingExtensions
  include PriorityExtensions
  extend CsvExchange::Model

  scope :active, where(:deleted => 0, :archived => 0)
  scope :deleted, where(:deleted => 1)

  # default ordering
  scope :ordered, order('priority DESC, name ASC')

  acts_as_versioned
  self.locking_column = :version

  belongs_to :project
  has_and_belongs_to_many :test_areas
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updater, :class_name => 'User', :foreign_key => 'updated_by'

  has_and_belongs_to_many_versioned :cases, :include_join_fields => [:position]

  validates_presence_of :name, :project_id, :date

  validates_uniqueness_of :external_id, :scope => :project_id, :allow_nil => true

  def avg_duration
    Case.total_avg_duration(self.case_ids)
  end

  def to_data(*opts)
    if opts.include? :brief
      return {
        :name     => self.name,
        :date => self.date,
        :id       => self.id,
        :version  => self.version,
        :tag_list => self.tags_to_s,
        :deleted  => self.deleted,
        :archived => self.archived,
        :average_duration => self.avg_duration,
        :priority => self.priority_name,
        :test_area_ids => self.test_area_ids
      }
    end

    {
      "name" => self[:name],
      "date" => self.date,
      "updated_at" => self[:updated_at],
      "project_id" => self[:project_id],
      "created_by" => self[:created_by],
      "updated_by" => self[:updated_by],
      "id" => self[:id],
      "version" => self[:version],
      "deleted" => self[:deleted],
      'archived' => self.archived,
      "created_at" => self[:created_at],
      "average_duration" => self.avg_duration,
      "priority" => self.priority_name,
      "test_area_ids" => self.test_area_ids
    }
  end

  def to_tree
    {
      :text => self.name,
      :leaf => true,
      :dbid => self.id,
      :deleted => self.deleted,
      :archived => self.archived,
      :cls => "x-listpanel-item priority_#{self.priority}",
      :tags => self.tags_to_s
    }
  end

  def next_free_case_position
    (self.cases.map{|c| c.position}.sort.last || 0) + 1
  end

  def self.create_with_cases!(atts, case_data, tag_list=nil)
    set = nil
    transaction do
      new_cases = case_data.map{|ci| Case.find(ci)}
      (1..new_cases.size).each {|pos| new_cases[pos-1].position = pos}

      set = TestSet.create!(atts)
      set.cases << new_cases
      set.tag_with(tag_list) unless tag_list.blank?
    end
    set
  end

  def update_with_cases!(atts, case_data, tag_list=nil)
    transaction do
      # TODO: check if cases in current project?
      new_cases = case_data.map{|ci| Case.find(ci)}
      (1..new_cases.size).each {|pos| new_cases[pos-1].position = pos}

      self.update_attributes!(atts)
      self.cases << new_cases
      self.tag_with((tag_list || ''))
    end
  end
  
  define_csv do
    attribute   :id,           'Test Set Id', :identifier => true
    attribute   :name,         'Name'
    attribute   :date,         'Date'
    attribute   :priority,     'Priority', :map => :to_i
    field       :avg_duration, 'Average Duration'
    association :tags,         'Tags', :map => :name
    association :test_areas,   'Test Areas', :map => :name
    children    :cases
  end

end
