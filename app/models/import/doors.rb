require 'csv'

module Import

=begin rdoc

=DoorsImport
Class for importing Doors exported CSV files.

This class is used firstly for importing Doors requirements and 
secondly for updating existing set of requirements by tracking
Doors object identifier.

=end
class Doors < Import::Base
  
  ########## ReqBuilder Starts ###########
  class ReqBuilder
    attr_accessor :attributes, :temps, :optionals
    
    def initialize(headers, val_arr, project_id, importer_id, 
                   logger, opts={})
      @attributes = {:project_id => project_id,
                     :created_by => importer_id,
                     :date => Date.today}
      @temps = {}
      @headers = headers
      @val_arr = val_arr
      @optionals = {}
      @logger = logger
      @opts = opts
    end
    
    def create_entity(klass, atts, tag_with="",
                      c_opts = {:create_method => :create!,
                                :add_to_assocs => {},
                                :store_temps => [],
                                :store_key => klass.to_s.underscore})                       
      store_temps = c_opts.delete(:store_temps)
      store_key = c_opts[:store_key] || klass.to_s.underscore
      
      entity = Import::Service.instance.create_entity(klass, atts, tag_with, 
        @logger, c_opts)
      
      if entity
        (store_temps || []).each do |t|
          @temps[(store_key+"_"+t.to_s).to_sym] = entity.send(t)
        end
      end
    end
    
    def parent_info(klass, store_key=nil)
      return nil unless @opts[:parent]
      key = (store_key || klass.to_s.underscore)
      key = (key + '_id').to_sym
      @opts[:parent].reverse.detect {|p| !p[key].nil?}
    end
    
    def current(klass)
      klass.find_by_id(@temps["#{klass.to_s.underscore}_id".to_sym])
    end
    
    def parent(klass, search_db=false, store_key=klass.to_s.underscore)
      if search_db # in addition, search database with parents' external_id
        parent_stack = (@opts[:parent] || []).dup
        parent = nil
        while parent.nil? and (p = parent_stack.pop)
          parent = klass.find_by_project_id_and_external_id(
            @attributes[:project_id], p[:external_id])
        end
        return parent if parent
      end
      info = parent_info(klass, store_key)
      return nil unless info
      klass.find_by_id info[(store_key+'_id').to_sym]
    end
    
    def init_attributes
      @val_arr.each_with_index do |val,i|
        send("#{@headers[i]}=", val)
      end
      @attributes[:name] = "#{@temps[:object_heading]} #{@temps[:object_text]}".strip
      @attributes[:description] = "#{@temps[:object_text]} #{@temps[:dof]}".strip
      @attributes[:test_area_ids] = @opts[:test_area_ids]
    end
    
    ### --- Attribute handling ---
    def object_identifier=(val)
      @attributes[:external_id] = val
      @temps[:external_id] = val
    end
    def priority=(val); @attributes[:priority] = val; end
    def description_of_the_feature=(val); @temps[:dof] = val; end
    def object_heading=(val); @temps[:object_heading] = val; end
    def object_level=(val); @temps[:object_level] = val.to_i; end
    def object_text=(val); @temps[:object_text] = val; end
    
    def last_modified_on=(val)
      # d(d).m(m).yyyy
      if val =~ /(\d{1,2})\.(\d{1,2})\.(\d{4})/
        d = Date.parse("#{$3}-#{$2}-#{$1}")
      else
        d = Date.parse(val)
      end
      @attributes[:external_modified_on] = d
    end
    ### ---
    
    def build_req
      # sync by external_id
      raise "No object identifier!" unless @attributes[:external_id]
      req = Import::Service.instance.find_ext_entity(Requirement, @attributes)
      
      if req
        @temps[:requirement_id] = req.id
        Import::Service.instance.update_entity(req, 
          @attributes.merge(:optionals => @optionals), @logger, 
          @opts.merge(:update_method => :update_keeping_cases))
      else
        create_entity(Requirement, 
                      @attributes.merge(:optionals => @optionals),
                      tags_for(Requirement), 
                      {:add_to_assocs => {}, :store_temps => [:id, :name],
                      :create_method => :create!})
      end
    end
    
    def build_case
      atts = {:project_id => @attributes[:project_id],
              :created_by => @attributes[:created_by],
              :updated_by => @attributes[:created_by],
              :name => @attributes[:name],
              :date => @attributes[:date],
              :external_id => @attributes[:external_id],
              :change_comment => 'Doors import',
              :test_area_ids => @attributes[:test_area_ids]}
      
      assocs = {}
      if req = current(Requirement)
        assocs[req.cases] = "corresponding requirement"
      end

      if ts = parent(TestSet, true)
        atts[:position] = ts.next_free_case_position
        assocs[ts.cases] = "test set '#{ts.name}'"
      end
      
      create_entity(Case, atts, tags_for(Case),
                    {:create_method => :create_with_dummy_step,
                     :add_to_assocs => assocs,
                     :store_temps => []})
    end
    
    def build_tag(klass)
      create_entity(Tag, {:name => @attributes[:name],
                          :project_id => @attributes[:project_id],
                          :taggable_type => klass.to_s }, '', 
                    {:create_method => :find_or_create_by_name_and_taggable_type,
                     :store_temps => [:name, :id, :taggable_type],
                     :store_key => "#{klass.to_s.underscore}_tag",
                     :create_msg => "Creating #{klass} Tag"})
    end
    
    def build_test_set
      create_entity(TestSet, {:project_id => @attributes[:project_id],
                              :created_by => @attributes[:created_by],
                              :updated_by => @attributes[:created_by],
                              :name => @attributes[:name],
                              :date => @attributes[:date],
                              :external_id => @attributes[:external_id],
                              :test_area_ids => @attributes[:test_area_ids]},
                    @opts[:global_tags],
                    {:store_temps => [:id, :version, :name],
                     :create_method => :create!})
    end
    
    # the main build method
    def req!
      init_attributes
      @logger.info "Row #{@opts[:row_num]}, object level #{@temps[:object_level]}:"
      
      raise "No object level!" unless @temps[:object_level]
      
      unless @opts[:import_range].include?(@temps[:object_level])
        @logger.info "Skipping #{@attributes[:name]}.."
        return
      end
      
      build_tag(Requirement) if @opts[:requirement_tag_level] == @temps[:object_level]
      build_req if @opts[:requirement_range].include?(@temps[:object_level])
      build_case if @opts[:case_range].include?(@temps[:object_level])
      build_tag(Case) if @opts[:case_tag_level] == @temps[:object_level]
      build_test_set if @opts[:set_level] == @temps[:object_level]
    end
    
    def tags_for(klass)
      tag_with = @opts[:global_tags] || ""
      p_tag = parent(Tag, false, "#{klass.to_s.underscore}_tag")
      if p_tag and p_tag.taggable_type == klass.to_s
        tag_with = (p_tag.name + ',' + tag_with).chomp(',')
      end
      tag_with
    end
    
    def method_missing(meth, *args)
      @optionals[meth.to_s.chop.humanize] = args[0].to_s
    end
  end
  ########## ReqBuilder Ends ###########
  
  class DryRun < StandardError; end
  
  def initialize(project_id, importer_id, io_ob, opts={})
    @project_id = project_id
    @importer_id = importer_id
    @io_ob = io_ob
    @opts = opts
    @log = StringIO.new
    @logger = ImportLogger.new(@log)    
    process
  end
  
  def log; @log.string; end
  
  private
  
  # keep a stack of parent rows for storing the test set id and requirement
  # id created in earlier rows
  def update_parent_opts(old_p_opts=nil, req_b=nil)
    return {:parent => []} if old_p_opts.nil? or req_b.nil?
    opts = old_p_opts.dup
    if old_p_opts[:parent].empty?
      opts[:parent] = [req_b.temps]
    else
      parent = opts[:parent].last
      # remove old parents
      while parent and parent[:object_level] >= req_b.temps[:object_level]
        opts[:parent].pop
        parent = opts[:parent].last
      end
      opts[:parent] << req_b.temps
    end
    opts
  end
  
  def get_headers
    @logger.info "Row 1: Headings"
    h_row = @io_ob.gets
    headers = CSV.parse(h_row).first.map do |h| 
      h.gsub('"', '').gsub(' ','_').downcase
    end
    %w(object_identifier object_level priority last_modified_on).each do |f|
      unless headers.include?(f)
        raise "Column '#{f.humanize}' required in import file!"
      end
    end
    if !headers.include?('object_text') and !headers.include?('object_heading')
      raise "Column 'Object text' or 'Object heading' required in import file!"
    end
    headers
  end
  
  def email_log
    email = User.find(@importer_id).email
    @logger.info "Emailing log to #{email}.."
    unless @opts[:dry_run]
      ImportNotifier.deliver_import_notice(@log.string, "Doors import", email)
    end
  end
  
  def process
    begin
      builder = nil
      parent_opts = nil
      headers = get_headers
      data = @io_ob.read
      row_num = 2
      proj = Project.find(@project_id)
      old_req_ids = proj.requirement_ids
      imported_req_ids = []
      
      ActiveRecord::Base.transaction do
        CSV.parse(data) do |row|
          parent_opts = update_parent_opts(parent_opts, builder)
          builder = ReqBuilder.new(headers, row, @project_id, 
                                   @importer_id, @logger, 
                                   @opts.merge(parent_opts).merge(
                                   {:row_num => row_num}))
          builder.req!
          imported_req_ids << builder.temps[:requirement_id]
          row_num += 1
        end
        
        Import::Service.instance.update_entity(proj, 
          {:old_req_ids => old_req_ids, 
           :imported_req_ids => imported_req_ids.uniq}, @logger, @opts)
        
        email_log
        
        raise DryRun.new("Simulation done.") if @opts[:dry_run]
      end
      
      @io_ob.close
      
    rescue DryRun => dr
      @logger.info dr.message
    rescue Exception => e
      @logger.error_msg Sanitizer.instance.escape_once(e.message)
    end
  end
  
end


end # module Import
