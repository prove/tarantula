# -*- coding: utf-8 -*-
=begin rdoc

A requirement. Versioned many-to-many association to cases.

=end
class Requirement < ActiveRecord::Base
  include AttachingExtensions
  include TaggingExtensions
  extend CsvExchange::Model
  
  acts_as_versioned
  self.locking_column = :version
  
  belongs_to :project
  has_and_belongs_to_many_versioned :cases
  
  has_and_belongs_to_many :test_areas
  belongs_to :creator, :foreign_key => 'created_by', :class_name => 'User'
  has_many :tasks, :class_name => 'Task::Base', :as => :resource, 
           :dependent => :destroy
  
  validates_presence_of :external_id, :message => "id can't be blank"
  validates_presence_of :date, :name, :project_id, :created_by
  
  validates_uniqueness_of :external_id, :scope => :project_id, 
    :message => 'id has already been taken'
  
  # default ordering
  scope :ordered, order('name ASC')
  
  scope :active, where(:deleted => 0, :archived => 0)
  scope :deleted, where(:deleted => 1)
  
  def to_data
    {
      :name => self.name,
      :id => self.id,
      :date => self.date,
      :priority => self.priority,
      :description => self.description,
      :optionals => self.optionals,
      :external_id => self.external_id,
      :deleted => self.deleted,
      :archived => self.archived,
      :created_at => self.created_at,
      :updated_at => self.updated_at,
      :tag_list => self.tags_to_s,
      :test_area_ids => self.test_area_ids
     }
  end
  
  def to_tree
    {
      :text => self.name,
      :leaf => true,
      :dbid => self.id,
      :deleted => self.deleted,
      :archived => self.archived,
      :cls => 'x-listpanel-item',
      :tags => self.tags_to_s
    }
  end
  
  def cases_on_test_area(ta)
    self.cases.select{|c| c.test_area_ids.include?(ta.id)}
  end
  
  def self.create_with_cases!(atts, cases, tags=nil)
    req = nil
    transaction do
      req = Requirement.create!(atts)
      req.cases << cases.uniq
      req.tag_with(tags) unless tags.blank?
    end
    req
  end
  
  def update_with_cases!(atts, cases, tags)
    transaction do
      self.update_attributes!(atts)
      self.cases << cases.uniq
      self.tag_with((tags || ""))
    end
  end
  
  # variant used in import process
  def update_keeping_cases(atts)
    transaction do
      case_ids = self.case_ids
      self.update_attributes!(atts)
      self.cases << Case.find(case_ids)
    end
  end
  
  # Create new version of requirement with given case added
  def add_case(case_id)
    transaction do
      case_ids = self.case_ids
      case_ids << case_id
      case_ids.uniq!
      self.save!
      self.cases<< Case.find(case_ids)
    end
  end

  # Create new version of requirement with given case removed
  def remove_case(case_id)
    transaction do
      case_ids = self.case_ids
      case_ids.delete(case_id)
      self.save!
      self.cases<< Case.find(case_ids)
      self.save_version
    end
  end
  
  def optionals=(data)
    self['optionals'] = YAML.dump(data)
  end
  
  def optionals
    self['optionals'].nil? ? nil : YAML.load(self['optionals'])
  end
  
  def self.id_sort!(reqs)
    reqs.sort! do |a,b|
      a_parts = a.external_id.id_parts
      b_parts = b.external_id.id_parts
      if a_parts[0].blank? and b_parts[0].blank?
        a_parts[1] <=> b_parts[1]
      elsif a_parts[0].blank? or b_parts[0].blank?
        a_parts[0].blank? ? -1 : 1
      else
        if a_parts[0] == b_parts[0]
          a_parts[1] <=> b_parts[1]
        else
          a_parts[0] <=> b_parts[0]
        end
      end
    end
  end

  define_csv do
    attribute   :id,          'Requirement Id', :identifier => true
    attribute   :external_id, 'External Id'
    attribute   :name,        'Name'
    attribute   :date,        'Date'
    attribute   :priority,    'Priority', :map => :to_i
    field       :updated_at,  'Modified at'
    association :tags,        'Tags', :map => :name
    association :test_areas,  'Test Areas', :map => :name
    attribute   :description, 'Description'
    children    :cases
  end
  
end
