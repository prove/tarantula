=begin rdoc

= BugTracker
This is the base class of bug trackers. Inherit via STI.
The public interface follows.

bugs_for_project(proj, user=nil):: return list of project's bugs (visible to user)
products_for_project(proj, clf_name=nil):: return products for project
fetch_bugs(opts={}):: fetch bugs, use opts[:force_update] to force update of all bugs
reset_last_fetched:: reset the time when bugs were last fetched
bug_show_url(external_bug_id):: url to open bug in tracker
bug_post_url(project, opts={}):: url to post a bug in tracker. opts[:product] & opts[:step_execution_id] provided.
refresh!:: refresh bugs, severities, products, etc.
to_tree:: return tree data for tracker
to_data:: return data for tracker

=end
class BugTracker < ActiveRecord::Base
  attr_accessible :type, :name, :base_url, :db_host, :db_name, :db_user,
                  :db_passwd, :sync_project_with_classification, :last_fetched,
                  :import_source
  
  has_many :severities, :class_name => 'BugSeverity', :dependent => :destroy
  has_many :products, :class_name => 'BugProduct', :dependent => :destroy
  has_many :bug_components, :through => :products
  alias_method :components, :bug_components
  has_many :projects
  has_many :bugs, :dependent => :destroy
  has_many :snapshots, :class_name => 'BugTrackerSnapshot', :dependent => :destroy

  before_save :ping
  after_create :refresh!

  validates_presence_of :name, :base_url

  def bugs_by(hash_by, proj, test_area, bscope=:s_open, snapshot_offset=0, include_name=false)
    ret = ActiveSupport::OrderedHash.new
    if snapshot_offset > 0
      container = self.snapshots.find(:first, :offset => snapshot_offset-1,
                                      :order => 'created_at desc')
      name = container.try(:name)
    else
      container = self
      name = "Current"
    end
    return nil if container.nil?
    
    bug_data = nil
    if bscope == :s_open
      bug_data = container.bugs.send(:s_open, self.type)
    elsif bscope == :not_closed
      bug_data = container.bugs.send(:not_closed, self.type)
    else
      bug_data = container.bugs
    end
    bug_data = bug_data.ordered.where(:bug_product_id => test_area ? test_area.bug_product_ids : proj.bug_product_ids).includes(:severity)

    bug_data.each do |bug|
      key = bug.instance_eval(hash_by)
      ret[key] ||= []
      ret[key] << bug
    end
    return [name, ret] if include_name
    ret
  end

  def take_snapshot(name)
    BugTrackerSnapshot.create!(:bug_tracker => self, :name => name)
  end

  def bug_label(bug)
    "\##{bug.external_id} #{bug.summary}"
  end

  private

  # override in subclass with a real implementation
  def ping; end
  def refresh!; end

  def logger
    return @logger if @logger
    @logger = Import::ImportLogger.new("#{Rails.root}/log/bug_trackers.log", 5,
                                       100.megabytes)
    @logger.markup = false
    @logger
  end

  def log_init_start(klass, refresh)
    verb = (refresh ? 'Refreshing' : 'Importing')
    logger.info "#{verb} #{klass.to_s.underscore.humanize.pluralize} "+
                "for tracker '#{self.name}' (id #{self.id}).."
  end

  def associated_ext_entity(assoc, eid)
    entity = nil
    unless entity = self.send(assoc).find_by_external_id(eid)
      self.send("init_#{assoc}")
      entity = self.send(assoc).find_by_external_id(eid)
      raise "#{assoc.to_s.capitalize} sync problem!" unless entity
    end
    entity
  end

  def active_product_ids
    projects.map{|p| p.bug_products.map(&:external_id)}.flatten.uniq
  end

end
