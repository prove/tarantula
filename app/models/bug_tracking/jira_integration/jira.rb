=begin rdoc

Model reflecting connection to a bug tracker.

Jira via MySQL.

Fields
* name
* base_url
* db_host
* db_port
* db_name
* db_user
* db_passwd

=end
class Jira < BugTracker
  after_initialize :establish_connections
  belongs_to :import_source

  UDMargin = 5.minutes # update margin
  include ActionView::Helpers::TagHelper

  #validates_presence_of :db_host, :db_name, :db_user
  validates_presence_of :import_source

  def establish_connections
    if self.import_source
      JiraIssue.establish_connection(self.import_source.attributes)
      JiraProject.establish_connection(self.import_source.attributes)
      JiraPriority.establish_connection(self.import_source.attributes)
      JiraStatus.establish_connection(self.import_source.attributes)
      JiraUserProfile.establish_connection(self.import_source.attributes)
    end
  end


  ### PUBLIC BUG TRACKER INTERFACE ###
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

    prods = self.products

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
        profile_hash = JiraUserProfile.all
        service = Import::Service.instance

        JiraIssue.recent_from_projects(prids,self.last_fetched,force_update).each do |bug|
          prof = profile_hash.detect{|p| p['username'] == bug['reporter']}
          creator = (prof ? User.find_by_email(prof['username']) : nil)

          sev  = associated_ext_entity(:severities, bug.priority.id)
          prod = associated_ext_entity(:products,   bug.project.id)

          data = {:lastdiffed       => bug.updated,
                  :bug_severity_id  => sev.id,
                  :bug_tracker_id   => self.id,
                  :external_id      => bug.id,
                  :name             => bug.summary,
                  :bug_product_id   => prod.id,
                  :status           => bug.status.value,
                  :desc             => bug.desc,
                  :created_by       => creator ? creator.id : nil,
                  :url              => bug.url_part}

          old = service.find_ext_entity(Bug, data)

          if old
            if force_update or \
              (data[:lastdiffed] and (data[:lastdiffed] > self.last_fetched))
              service.update_entity(old, data, logger, opts)
            end
          else
            create_opts = {:create_method => :create!}.merge(opts)
            e = service.create_entity(Bug, data, "", logger, create_opts)
          end
        end
        sweep_moved_bugs
        update_attributes!(:last_fetched => Time.now)
      end
      logger.info "Done."
    rescue Exception => e
      logger.error_msg escape_once("#{e.message}\n#{e.backtrace}")
    end
  end

  def refresh!
    init_products(true)
    init_severities(true)
  end

  def to_tree
    {:id => self.id,
     :name => self.name }
  end

  def to_data
    {:id => self.id,
     :type => self["type"],
     :name => self.name,
     :base_url => self.base_url,
     :db_host => self.import_source.host,
     :db_port => self.import_source.port,
     :db_name => self.import_source.database,
     :db_user => self.import_source.username,
     :db_passwd => self.import_source.password,
     :bug_products => self.products.map(&:to_data)}
  end

  def reset_last_fetched
    self.update_attributes!(:last_fetched => 100.years.ago)
  end

  def bug_show_url(bug)
    self.base_url.chomp('/') + "/browse/#{bug.url}"
  end

  # opts[:product] and opts[:step_execution_id] provided
  def bug_post_url(project, opts={})
    se = StepExecution.find(opts[:step_execution_id])
    bp = BugProduct.find_by_name(opts[:product])
    name = se.case_execution.test_case.name
    comment = "[Tarantula] Case \"#{name}\", Step #{se.position}"

    url = self.base_url.chomp('/')
    url += "/secure/CreateIssueDetails!init.jspa?#{bp.external_id.to_s.to_query(:pid) if bp}" +
      "&issuetype=1&#{comment.to_query(:description)}"
  end

  def bug_label(bug)
    "[#{bug.url}] #{bug.summary}"
  end

  def ping
    JiraIssue.establish_connection(self.import_source.attributes)
    raise 'Couldn\'t connect to Jira database' unless (JiraIssue.connection and JiraIssue.connected?)
  end

  private

  def init_products(refresh=false)
    log_init_start(BugProduct, refresh)
    eids = []
    begin
      self.transaction do
        JiraProject.all.each do |proj|
          eids << proj.id
          atts = {:name => proj.name, :external_id => proj.id,
                  :bug_tracker_id => self.id}
          Import::Service.instance.create_or_update_ext_entity(BugProduct, atts,
            "", logger)
        end
        # remove products which dont exist anymore
        self.products.find(:all, :conditions => ["external_id not in (:eids)",
                                 {:eids => eids}]).map(&:destroy)
      end
      logger.info "Done."
    rescue Exception => e
      logger.error_msg escape_once("#{e.message}\n#{e.backtrace}")
    end
  end

  # create severities for this tracker
  def init_severities(refresh=false)
    log_init_start(BugSeverity, refresh)
    eids = []
    begin
      self.transaction do
        JiraPriority.all.each do |pri|
          eids << pri.id
          atts = {:bug_tracker_id => self.id, :name => pri.value,
                  :sortkey => pri.sortkey, :external_id => pri.id}
          Import::Service.instance.create_or_update_ext_entity(BugSeverity, atts,
            "", logger)
        end
        # remove severities which dont exist anymore
        self.severities.find(:all, :conditions => ["external_id not in (:eids)",
                            {:eids => eids}]).map(&:destroy)
      end
      logger.info "Done."
    rescue Exception => e
      logger.error_msg escape_once("#{e.message}\n#{e.backtrace}")
    end
  end

  # Remove bugs which are no more in the products of the tracker.
  # => Has to be done because only bugs which belong to tracker's products
  # are updated.
  def sweep_moved_bugs
    time = self.last_fetched
    bug_eids = JiraIssue.from_projects(active_product_ids).map{|i|i.id}

    sweepable = self.bugs.find(:all,
                               :conditions => ["lastdiffed >= :t",{:t => time}]).map{|b|b.external_id.to_i} - bug_eids

    sweepable.each do |eid|
      logger.info "Sweeping bug with external_id #{eid}.."
      self.bugs.find_by_external_id(eid).destroy
    end
  end

end
