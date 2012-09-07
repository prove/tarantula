=begin rdoc

Model reflecting connection to a bug tracker.

Bugzilla via MySQL. Refactor later if different trackers needed.

Fields
* name
* base_url
* db_host
* db_port
* db_name
* db_user
* db_passwd

=end
class Bugzilla < BugTracker # STI
  UDMargin = 5.minutes # update margin
  include ActionView::Helpers::TagHelper

  validates_presence_of :db_host, :db_name, :db_user

  ### DATABASE ###
  class DB
    def initialize(host, user, passwd, name, port)
      @connection = Mysql2::Client.new(:host => host, 
                                       :username => user, 
                                       :password => passwd, 
                                       :database => name, 
                                       :port => port)
    end

    def get_components
      @connection.query('select name,id,product_id from components;')
    end

    def get_products
      @connection.query('select name,id from products;')
    end

    def get_products_for_classification(clf_name)
      res = @connection.query(
              "select id from classifications where name='#{clf_name}';")
      row = res.first
      raise "No classification found with name \"#{clf_name}\"" unless row
      cl_id = row['id']
      prod_eids = []

      @connection.query("select id from products "+
               "where classification_id='#{cl_id}'").each do |prod|
        prod_eids << prod['id']
      end
      prod_eids
    end

    def get_bugs(prids, last_fetched, force_update)
      sql = "select * from bugs where product_id in (#{prids.join(',')})"
      unless force_update
        sql += " and ((lastdiffed is null) or "+
               "(lastdiffed >= '#{(last_fetched-UDMargin).to_s}'))"
      end
      @connection.query(sql)
    end

    def get_bug_ids_for_products(prids)
      sql = "select bug_id from bugs where product_id in (#{prids.join(',')})"
      ids = []
      @connection.query(sql).each{|h| ids << h['bug_id']}
      ids
    end

    def bugzilla_severities
      @connection.query("select * from bug_severity;")
    end

    def bugzilla_profiles
      @connection.query("select * from profiles;")
    end

    def get_longdesc(ext_id)
      res = @connection.query(
              "select thetext from longdescs where bug_id=#{ext_id};")
      res.first['thetext']
    end

    def bugzilla_time(parse=false)
      res = @connection.query("select now() as time;", :cast => false)
      t = res.first['time']
      t = Time.parse(t) if parse
      t
    end

    def ping; @connection.ping end
  end

  class MockDB
    class MockResult
      def initialize(result=[]); @result = result end
      def each(&blk); @result.each {|r| blk.call(r) } end
    end
    def get_components; MockResult.new end
    def get_products; MockResult.new end
    def get_products_for_classification(clf_name); [] end
    def get_bugs(prids, last_fetched, force_update); MockResult.new end
    def get_bug_ids_for_products(prids); [] end
    def bugzilla_severities; [] end
    def bugzilla_profiles; [] end
    def get_longdesc(ext_id); "long desc.." end
    def bugzilla_time(parse=false)
      t = Time.now
      parse ? t : t.to_s
    end
    def ping; true end
  end

  def mock=(val)
    val ? @db = MockDB.new : db
  end
  ### DATABASE ###

  def bugs_for_project(proj, user=nil)
    if user and (ta = user.test_area(proj)) and ta.forced and !ta.bug_product_ids.empty?
      prod_ids = ta.bug_product_ids
    else
      prod_ids = proj.bug_products.map(&:id)
    end
    bugs.not_closed(self[:type]).ordered.find(:all,
                                 :conditions => {:bug_product_id => prod_ids})
  end

  # returns all products + their possible mapping to proj's test_areas
  # if proj is nil, just return products
  def products_for_project(proj, clf_name=nil)
    res = []
    test_areas = (proj ? proj.test_areas : [])

    if self.sync_project_with_classification
      prods = products_for_classification(clf_name ? clf_name : proj.name)
    else
      prods = self.products
    end

    test_areas.each do |ta|
      ta.bug_products.each do |prod|
        res << {:bug_product_id => prod.id, :bug_product_name => prod.name,
                :included => true,
                :test_area_id => ta.id, :test_area_name => ta.name}
      end
    end

    prods = prods.select{|p| !res.detect{|r| r[:bug_product_id] == p.id}}

    prods.each do |prod|
      h = {:bug_product_id => prod.id, :bug_product_name => prod.name}
      if proj
        h.merge!(:included => proj.bug_product_ids.include?(prod.id))
      elsif self.sync_project_with_classification
        h.merge!(:included => true) # new project
      end
      res << h
    end
    res
  end

  # Uses Import::Service for bringing bugs in
  def fetch_bugs(opts={})
    force_update = opts.delete(:force_update) # other opts delivered to Import::Service

    logger.info "Fetching bugs for tracker '#{self.name}' (id #{self.id}).."

    prids = active_product_ids
    if prids.empty?
      logger.info "No products."
      return
    end

    begin
      self.transaction do
        severity_hash = db.bugzilla_severities
        profile_hash = db.bugzilla_profiles
        service = Import::Service.instance

        db.get_bugs(prids,self.last_fetched,force_update).each do |bug|
          prof = profile_hash.detect{|p| p['userid'] == bug['reporter']}
          creator = (prof ? User.find_by_email(prof['login_name']) : nil)

          b_sev = severity_hash.detect{|s| s['value'] == bug['bug_severity']}
          raise "Invalid severity ref in bugzilla! (#{bug['bug_severity']})" \
            unless b_sev

          sev  = associated_ext_entity(:severities, b_sev['id'])
          prod = associated_ext_entity(:products,   bug['product_id'])
          comp = associated_ext_entity(:components, bug['component_id'])

          data = {:lastdiffed       => bug['lastdiffed'],
                  :bug_severity_id  => sev.id,
                  :bug_tracker_id   => self.id,
                  :external_id      => bug['bug_id'],
                  :name             => bug['short_desc'],
                  :bug_product_id   => prod.id,
                  :bug_component_id => comp.id,
                  :status           => bug['bug_status'],
                  :priority         => bug['priority'],
                  :desc             => db.get_longdesc(bug['bug_id']),
                  :created_by       => creator ? creator.id : nil }

          old = service.find_ext_entity(Bug, data)

          if old
            service.update_entity(old, data, logger, opts)
          else
            create_opts = {:create_method => :create!}.merge(opts)
            e = service.create_entity(Bug, data, "", logger, create_opts)
          end
        end
        sweep_moved_bugs
        update_attributes!(:last_fetched => db.bugzilla_time)
      end
      logger.info "Done."
    rescue Exception => e
      logger.error_msg escape_once("#{e.message}\n#{e.backtrace}")
    end
  end

  def refresh!
    init_products(true)
    init_severities(true)
    init_components(true)
  end

  def to_tree
    {:id => self.id,
     :name => self.name }
  end

  def to_data
    {
      :id => self.id,
      :type => self["type"],
      :name => self.name,
      :base_url => self.base_url,
      :db_host => self.db_host,
      :db_port => self.db_port,
      :db_name => self.db_name,
      :db_user => self.db_user,
      :db_passwd => self.db_passwd,
      :bug_products => self.products.map(&:to_data),
      :sync_project_with_classification => self.sync_project_with_classification
    }
  end

  def db_host=(val)
    self['db_host'] = val
    # reset last_fetched if db_host changed
    self['last_fetched'] = 100.years.ago unless self.new_record?
  end

  def reset_last_fetched
    self.update_attributes!(:last_fetched => 100.years.ago)
  end

  def bug_show_url(bug)
    self.base_url.chomp('/') + "/show_bug.cgi?id=#{bug.external_id}"
  end

  # opts[:product] and opts[:step_execution_id] provided
  def bug_post_url(project, opts={})
    se = StepExecution.find(opts[:step_execution_id])
    name = se.case_execution.test_case.name
    comment = "[Tarantula] Case \"#{name}\", Step #{se.position}"

    url = self.base_url.chomp('/')
    url += "/enter_bug.cgi?#{opts[:product].to_query(:product)}" +
           "&#{project.name.to_query(:classification)}" +
           "&#{comment.to_query(:comment)}"
    url
  end

  private

  # Remove bugs which are no more in the products of the tracker.
  # => Has to be done because only bugs which belong to tracker's products
  # are updated.
  def sweep_moved_bugs
    bug_eids = db.get_bug_ids_for_products(active_product_ids)

    sweepable = self.bugs.all.map(&:external_id) - bug_eids.map(&:to_s)

    sweepable.each do |eid|
      logger.info "Sweeping bug with external_id #{eid}.."
      self.bugs.find_by_external_id(eid).destroy
    end
  end

  def db
    @db ||= DB.new(self.db_host, self.db_user, self.db_passwd, self.db_name,
                   self.db_port)
  end

  def ping
    db.ping
  end

  # return all the products in the tracker
  # N.B. we can't destroy all the existing products as projects have associations
  #      to them
  def init_products(refresh=false)
    log_init_start(BugProduct, refresh)
    prod_eids = []
    begin
      self.transaction do
        db.get_products.each do |prod|
          prod_eids << prod['id']
          atts = {:name => prod['name'], :external_id => prod['id'],
                  :bug_tracker_id => self.id}
          Import::Service.instance.create_or_update_ext_entity(BugProduct, atts,
            "", logger)
        end
        # remove products which dont exist anymore
        self.products.find(:all, :conditions => ["external_id not in (:eids)",
                                 {:eids => prod_eids}]).map(&:destroy)
      end
      logger.info "Done."
    rescue Exception => e
      logger.error_msg escape_once("#{e.message}\n#{e.backtrace}")
    end
  end

  def init_components(refresh=false)
    log_init_start(BugComponent, refresh)
    comp_eids = []
    begin
      self.transaction do
        db.get_components.each do |comp|
          comp_eids << comp['id']
          prod = associated_ext_entity(:products, comp['product_id'])

          atts = {:name => comp['name'], :external_id => comp['id'],
                  :bug_product_id => prod.id}

          Import::Service.instance.create_or_update_ext_entity(BugComponent, atts,
              "", logger)
        end
        # remove components which dont exist anymore
        self.components.find(:all,
                :conditions => ["bug_components.external_id not in (:eids)",
                {:eids => comp_eids}]).map(&:destroy)
      end
      logger.info "Done."
    rescue Exception => e
      logger.error_msg escape_once("#{e.message}\n#{e.backtrace}")
    end
  end

  # create severities for this tracker
  def init_severities(refresh=false)
    log_init_start(BugSeverity, refresh)
    sev_eids = []
    begin
      self.transaction do
        db.bugzilla_severities.each do |sev|
          sev_eids << sev['id']
          atts = {:bug_tracker_id => self.id, :name => sev['value'],
                  :sortkey => sev['sortkey'], :external_id => sev['id']}
          Import::Service.instance.create_or_update_ext_entity(BugSeverity, atts,
            "", logger)
        end
        # remove severities which dont exist anymore
        self.severities.find(:all, :conditions => ["external_id not in (:eids)",
                            {:eids => sev_eids}]).map(&:destroy)
      end
      logger.info "Done."
    rescue Exception => e
      logger.error_msg escape_once("#{e.message}\n#{e.backtrace}")
    end
  end

  def products_for_classification(clf_name)
    prod_eids = db.get_products_for_classification(clf_name)
    self.products.find(:all, :conditions => {:external_id => prod_eids})
  end

end
