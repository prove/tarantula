=begin rdoc

A project. Access rights are given on a per-project basis.

=end
class Project < ActiveRecord::Base
  include AttachingExtensions

  alias_attribute :project_id, :id
  def project; self; end

  Priorities = [{:name => 'high',   :value => 1},
                {:name => 'normal', :value => 0},
                {:name => 'low',    :value => -1}]

  scope :active, where(:deleted => 0)
  scope :deleted, where(:deleted => 1)

  self.locking_column = :version
  has_many :assignments, :class_name => 'ProjectAssignment',
           :dependent => :destroy, :conditions => "`group` != 'ADMIN'"
  has_many :users, :through => :assignments

  has_many :cases, :dependent => :destroy
  has_many :requirements, :dependent => :destroy
  has_many :test_sets, :dependent => :destroy
  has_many :executions, :dependent => :destroy
  has_many :test_objects, :dependent => :destroy

  # All of project's tags in all resources
  has_many :tags, :dependent => :destroy

  # Test areas
  has_many :test_areas, :dependent => :destroy

  has_many :tasks, :class_name => 'Task::Base', :dependent => :destroy

  has_many :preferences, :class_name => 'Preference::Base', :dependent => :destroy

  belongs_to :bug_tracker
  has_and_belongs_to_many :bug_products

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false

  before_destroy do |proj|
    ProjectAssignment.destroy_all(:project_id => proj.id, :group => 'ADMIN')
  end

  def bug_components
    BugComponent.find(:all,
      :conditions => {:bug_product_id => self.bug_product_ids})
  end

  def open_bugs
    self.bug_products.map{|prod| prod.bugs.s_open(prod.bug_tracker[:type])}.flatten
  end

  def self.create_with_assignments!(atts, assigned_users, t_areas, b_products)
    project = nil
    transaction do
      project = Project.create!(atts)
      project.set_test_areas(t_areas)
      project.set_bug_products(b_products)
      project.set_users(assigned_users)
    end
    project
  end

  def update_with_assignments!(updater, atts, assigned_users, t_areas, b_products)
    raise "At least manager rights required!" unless \
      updater.allowed_in_project?(self.id, ['MANAGER'])
    raise "Only admin can change project's name!" if \
      self.name != atts['name'] and !updater.admin?

    transaction do
      self.update_attributes!(atts)
      set_test_areas(t_areas)
      set_bug_products(b_products)
      set_users(assigned_users)

      # Make sure that current is user is at least manager of current project.
      # This prevents user from accidentally removing user access from himself.
      unless updater.admin?
        pa = updater.project_assignments.find_by_project_id(self.id)
        if !pa
          updater.project_assignments.create!(
            :project_id => self.id, :group => 'MANAGER')
        elsif !['MANAGER', 'ADMIN'].include?(pa.group)
          pa.update_attribute(:group, 'MANAGER')
        end
      end
    end
  end

  def managers
    assignments.find_all_by_group('MANAGER', :include => :user)
  end

  def to_tree
    { :text => self.name, :dbid => self.id,
      :leaf => true, :deleted => self.deleted,
      :cls => 'x-listpanel-item x-listpanel-project',
    }
  end

  def to_data
    {
      :assigned_users => self.assignments.map(&:to_data),
      :name => self.name,
      :description => self.description,
      :deleted => self.deleted,
      :id => self.id,
      :library => self.library,
      :test_areas => self.test_areas.map(&:name).join(','),
      :bug_tracker_id => self.bug_tracker_id
    }
  end

  def purge!
    transaction do
      [Case, Execution, Requirement, TestSet, TestObject].each do |c|
        c.destroy_all(:project_id => self.id, :deleted => true)
      end
    end
  end

  def set_users(user_arr)
    self.assignments.delete_all

    user_arr.each do |u|
      user = User.find(:first, :conditions => {:login => u['login']})
      ta = nil # test area
      if u['test_area']
        ta = self.test_areas.find_by_name(u['test_area'])
        raise "Test area mismatch! Check that you have not removed a test "+
              "area which is mapped to a product or user." unless ta
      end

      user.project_assignments.create!(
          :project_id => self.id,
          :group => u['group'].upcase.tr(' ','_'),
          :test_area => ta,
          :test_area_forced => !u['test_area_forced'].blank?)
    end
  end

  # takes an array of hashes {:bug_product_id => x, :test_area_name => y}
  def set_bug_products(bp_arr)
    old_prod_ids = self.bug_product_ids

    self.bug_products.clear
    self.test_areas.map{|ta| ta.bug_products.clear}

    bp_arr.each do |row|
      row.symbolize_keys!
      prod = BugProduct.find(row[:bug_product_id])
      self.bug_products << prod unless self.bug_products.include?(prod)
      ta = (row[:test_area_name] ? row[:test_area_name].strip : nil)

      if !ta.blank?
        ta = self.test_areas.find_by_name(ta)
        raise "Test area mismatch! Check that you have not removed a test "+
              "area which is mapped to a product or user." unless ta
        ta.bug_products << prod unless ta.bug_products.include?(prod)
      end
    end
    self.bug_tracker.reset_last_fetched if self.bug_tracker and \
      (old_prod_ids.sort != self.bug_product_ids.sort)
    self.bug_products
  end

  # takes a csv string of test area names, existing or new
  # resets bug_products_id!
  def set_test_areas(ta_str)
    tas = ta_str.split(',').map(&:strip).select{|ta| !ta.blank?}.uniq

    tas.map do |ta|
      a = self.test_areas.find_by_name(ta)
      if a
        a.update_attributes!(:name => ta)
        a.bug_products.clear
      else
        self.test_areas.create!(:name => ta)
      end
    end
    self.test_areas.each do |ta|
      ta.destroy unless tas.include?(ta.name)
    end
    self.test_areas
  end

end
