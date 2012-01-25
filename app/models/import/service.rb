module Import

=begin rdoc

A singleton layer for importing entities. Handles logic like flagging cases
related to updated requirements.

=end
class Service
  include Singleton
  
  UpdatePolicies = {
    # Undelete all entities on update if deleted
    Object => lambda do |entity,atts,i_logger,opts|
      if entity.deleted  
        i_logger.update_msg "Undeleting.."
        entity.toggle!(:deleted)
      end
      true
    end,
    
    Project => lambda do |project, atts, i_logger, opts|
      return false if atts[:old_req_ids].empty? # first import -> no tasks
      project.reload
      current_req_ids = project.requirement_ids
      
      (current_req_ids - atts[:old_req_ids]).each do |new_id|
        req = Requirement.find(new_id)
        i_logger.create_msg \
          "Creating a task for new requirement \"#{req.name}\""
        Task::NewRequirement.create!(
          :resource    => req,
          :description => "New requirement \##{req.external_id}",
          :created_by  => req.created_by,
          :assigned_to => req.created_by,
          :project_id  => project.id)
      end
      
      (current_req_ids - atts[:imported_req_ids]).each do |deleted_id|
        req = Requirement.find(deleted_id)
        next if req.deleted?
        
        i_logger.create_msg \
          "Creating a task for deleted requirement \"#{req.name}\""
        Task::DeletedRequirement.create!(
          :resource    => req,
          :description => "Deleted requirement \##{req.external_id}",
          :created_by  => req.created_by,
          :assigned_to => req.created_by,
          :project_id  => project.id)
      end
      
      return false # don't really update project
    end,
    
    Bug => lambda do |entity,atts,i_logger,opts|
      if (atts[:status] == 'RESOLVED') and (entity.status != 'RESOLVED')
        if entity.creator and (se = entity.step_executions.first)
          i_logger.update_msg "Creating BugResolved task for a resolved bug..#{entity.external_id}"
          begin
            Task::BugResolved.create!(
                                      :resource    => entity, 
                                      :description => "Defect ##{entity.external_id} resolved.",
                                      :created_by  => entity.creator.identity,
                                      :assigned_to => entity.creator.id,
                                      :project_id  => se.case_execution.test_case.project_id)
          rescue
            i_logger.update_msg "FAIL: Original test case may be deleted. Unable to create task."
          end
        end
      end
      true
    end,
    
    # Create review tasks for requirement's cases when requirement updated
    Requirement => lambda do |req,atts,i_logger,opts|
      raise "Required field 'Last Modified On' missing! (update)" \
        unless atts[:external_modified_on]
      if req.external_modified_on and \
          (req.external_modified_on >= atts[:external_modified_on])
        i_logger.info "Not updating requirement '#{atts[:name]}', "+
                      "already up to date."
        return false
      end
      
      req.cases.each do |c|
        i_logger.update_msg "Creating review task for case '#{c.name}'.."
          c.tasks << Task::Review.create!(
            :resource    => c, 
            :description => "Review: #{c.name}",
            :created_by  => atts[:created_by],
            :assigned_to => atts[:created_by],
            :project_id  => c.project_id)
      end
      true
    end
  }
  
  # Entity is not created if a create policy return false
  CreatePolicies = {
    Class => lambda do |klass,atts,i_logger,opts|
      if atts[:external_id]
        old = Import::Service.instance.find_ext_entity(klass, atts)
        if old
          i_logger.info "Not creating #{klass} '#{atts[:name]}', "+
                        "it has been created earlier and still exists."
          return false
        end
      end
      return true
    end,
    
    Bug => lambda do |klass, atts, i_logger, opts|
      atts[:reported_via_tarantula] = true if atts[:desc] =~ /\[Tarantula\]/
      return true
    end
  }
  
  def create_entity(klass, atts, tag_with, i_logger,
                    opts = {:create_method => :create!,
                            :create_msg => nil,
                            :add_to_assocs => {}})
    
    CreatePolicies.each do |key, pol|
      if klass.is_a?(key) or klass == key
        return nil if (pol.call(klass, atts, i_logger, opts) == false)
      end
    end
    create_msg = opts[:create_msg] || "Creating #{klass}"
    i_logger.create_msg "#{create_msg} '#{atts[:name]}'.."
    i_logger.update_msg "Tagging with #{tag_with}.." unless tag_with.blank?
    
    (opts[:add_to_assocs] || []).each do |assoc,txt|
      i_logger.update_msg "Adding to #{txt}.."
    end
    
    entity = nil
    entity = klass.send(opts[:create_method], atts)
    (opts[:add_to_assocs] || []).each do |assoc,txt|
      assoc << entity
    end
    entity.tag_with(tag_with) unless tag_with.blank?
    entity
  end
  
  def update_entity(entity, atts, i_logger, opts={})
    UpdatePolicies.each do |key, pol|
      if entity.is_a?(key)
        return if (pol.call(entity,atts,i_logger,opts) == false)
      end
    end
    i_logger.update_msg "Updating #{entity.class} '#{atts[:name]}'.."
    entity.send(opts[:update_method] || :update_attributes!, atts)
    entity
  end
  
  def create_or_update_ext_entity(klass, atts, tag_with, i_logger, opts={})  
    if e = find_ext_entity(klass, atts)
      args = [e, atts, i_logger]
      args << opts unless opts.empty?
      update_entity(*args)
    else
      args = [klass, atts, tag_with, i_logger]
      args << opts unless opts.empty?
      create_entity(*args)
    end
  end
  
  def find_ext_entity(klass, atts)
    scope = "#{klass.external_id_scope}_id".to_sym
    klass.find(:first, :conditions => { scope => atts[scope],
               :external_id => atts[:external_id].to_s}, :lock => true)
  end
  
end

end # module Import
