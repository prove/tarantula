require 'digest'

=begin rdoc

A user.

=end
class User < ActiveRecord::Base
  scope :active, where(:deleted => 0)
  scope :deleted, where(:deleted => 1)

  self.locking_column = :version

  Groups = {
    :test_engineer     => 'TEST_ENGINEER',
    :test_designer     => 'TEST_DESIGNER',
    :manager           => 'MANAGER',
    :manager_view_only => 'MANAGER_VIEW_ONLY'
    # :admin => 'ADMIN'
  }

  alias_attribute :name, :login

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email

  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?

  validates_length_of       :login,    :within => 3..40
  validates :email, :presence => true, :uniqueness => true,
            :email_format => true


  validates_uniqueness_of   :login, :case_sensitive => false
  before_save :encrypt_password

  has_many :executions, :through => :case_executions, :source => :execution,
           :uniq => true

  has_many :case_executions, :foreign_key => 'assigned_to'

  has_many :cases_executed, :class_name => 'CaseExecution',
           :foreign_key => 'executed_by'

  has_many :project_assignments, :dependent => :destroy
  has_many :projects, :through => :project_assignments

  has_many :tasks, :class_name => 'Task::Base', :foreign_key => 'assigned_to'
  has_many :preferences, :class_name => 'Preference::Base'


  def latest_project
    pa = project_assignments.find(:first, :conditions =>
           {:project_id => self.latest_project_id})
    unless pa
      return nil if project_assignments.empty?
      pa = project_assignments.first
      update_attribute(:latest_project_id, pa.project_id)
    end
    pa.project
  end

  def allowed_in_project?(pid,req_groups = nil)
    return true if req_groups.nil?
    pa = self.project_assignments.find_by_project_id(pid)
    return false unless pa
    return req_groups.include?(pa.group)
  end

  # Print hash-table in Ext Tree format, which can be later
  # converted to json with to_json method
  def to_tree
    return {:dbid => self[:id], :text => self[:login], :leaf => true,
            :deleted => self[:deleted],
            :cls => 'x-listpanel-item x-listpanel-user',
            :realname => self[:realname]}
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = User.find_by_login(login) # need to get the salt

    if u.try(:authenticated?, password)
      # for forwards compatibility
      u.instance_eval{store_md5_password(password)}
      return u
    end
    return nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Generate new alpha numeric random password
  def new_random_password
    self.password= Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--")[0,6]
    self.password_confirmation = self.password
  end

  def to_data
    return { :id => self.id,
             :description => self.description,
             :phone => self.phone,
             :realname => self.realname,
             :login => self.login,
             :email => self.email,
             :admin => self.admin?,
             :version => self.version,
             :time_zone => self.time_zone,
             :deleted => self.deleted }
  end

  def test_area(project_or_project_id)
    project_id = project_or_project_id
    project_id = project_id.id if project_id.is_a?(Project)

    test_area = nil
    a = self.project_assignments.find_by_project_id(project_id)
    if a and a.test_area
      test_area = a.test_area
      test_area.forced = a.test_area_forced
    end
    test_area
  end

  def set_test_area(project_id, test_area_id, forced=false)
    project = Project.find(project_id)
    pa = self.project_assignments.find_by_project_id(project.id)
    raise "User #{self.id} has no assignment for project #{project_id}!" \
      unless pa
    if test_area_id.to_i == 0
      test_area = nil
    else
      test_area = project.test_areas.find(test_area_id)
    end

    pa.update_attributes!({:test_area => test_area,
                           :test_area_forced => forced})
  end

  # returns a dummy task for each execution user has
  # not run step_executions in (assigned to him)
  def execution_tasks
    execs = Execution.find(
      :all,
      :group => 'executions.id',
      :joins => [:case_executions, :project],
      :conditions => "case_executions.assigned_to=#{self.id} "+
                     "AND executions.deleted=0 AND executions.completed=0 "+
                     "AND case_executions.result='#{NotRun}' AND "+
                     "projects.deleted=0")
    execs.map do |e|
      count = e.case_executions.count(:conditions =>
        {:assigned_to => self.id, :result => NotRun.db})
      Task::Execution.new(e, self, count)
    end
  end

  def admin=(val)
    new_type = (val == true ? 'Admin' : 'User')
    self['type'] = new_type
  end

  def admin?; false; end

  protected

  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
    self.md5_password = Digest::MD5::hexdigest("#{self.login}:Testia:#{password}")
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def store_md5_password(passwd)
    update_attribute(:md5_password,
      Digest::MD5::hexdigest("#{self.login}:Testia:#{passwd}"))
  end
end
