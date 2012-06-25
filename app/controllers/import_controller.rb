
class ImportController < ApplicationController

  layout false

  # Uses following parameters
  # file::              the csv file to import
  # max_object_level::  don't import entities with object level beyond this
  # tags::              comma separated list of tag names to tag all entities with
  # simulate::          Do only a dry run if not nil
  #
  # requirement_tag_enabled:: Create a requirement tag?
  # requirement_tag_level::   Create tag of object level X entities
  #
  # requirement_enabled::  Create/update requirements?
  # requirement_min::      Min. object level to create reqs from
  # requirement_max::      Max. object level to create reqs from
  #
  # set_enabled::          Create test sets?
  # set_level::            Create test_sets from object level X entities
  #
  # case_tag_enabled::     Create a case tag?
  # case_tag_level::       Create tag of object level X entities
  # case_enabled::         Create test cases?
  # case_min::             Min. object level to create cases from
  # case_max::             Max. object level to create cases from
  def doors
    data = Sanitizer.instance.clean_data(params)
    
    @range = 1..10
    @test_areas = @project.test_areas
    
    pref = Preference::DoorsImport.for_project(@project).first || \
           Preference::DoorsImport.default(@project)
    
    if request.get?
      @data = pref.data
      return
    end
    
    file = data.delete(:file)
    data.delete(:controller)
    data.delete(:action)
    
    unless @current_user.allowed_in_project?(@project,
        ["MANAGER", "TEST_DESIGNER"])
      render :inline => '<span style="color:red">Permission denied.</span>'
      return
    end
    
    pref.update_attributes!(:data => data)
    
    if file.blank?
      render :inline => '<span style="color:red">Import file missing.</span>'
      return
    end

    req_tag_level = data[:requirement_tag_enabled] ? \
      data[:requirement_tag_level].to_i : 0
    req_range = data[:requirement_enabled] ? \
      (data[:requirement_min].to_i)..(data[:requirement_max].to_i) : 0..0
    case_tag_level = data[:case_tag_enabled] ? data[:case_tag_level].to_i : 0
    case_range = data[:case_enabled] ? \
      (data[:case_min].to_i)..(data[:case_max].to_i) : 0..0

    opts = {:import_range => 1..(data[:max_object_level].to_i),
            :global_tags  => data[:tags],
            :test_area_ids => data[:test_area].blank? ? [] : [data[:test_area]],
            :dry_run => data[:simulate].blank? ? false : true,
            :requirement_tag_level => req_tag_level,
            :requirement_range => req_range,
            :set_level => data[:set_enabled] ? data[:set_level].to_i : 0,
            :case_tag_level => case_tag_level,
            :case_range => case_range}

    i = Import::Doors.new(@project.id, @current_user.id, file, opts)

    @log = i.log
    render :template => '/import/log'
  end

end
