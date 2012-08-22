
module SmartTag

  TAGS = [SmartTag::AlwaysFailed,
          SmartTag::Best,
          SmartTag::Failed,
          SmartTag::NeverTested,
          SmartTag::NoLinkedCases,
          SmartTag::NotImplemented,
          SmartTag::NotIncludedInTestSet,
          SmartTag::NotLinkedToExecution,
          SmartTag::NotLinkedToReq,
          SmartTag::Resolved,
          SmartTag::Untagged]

  # Digest a tag string fed by UI.
  # returns [smart_tags, other_tags_ids]
  def self.digest(tag_str)
    return [[], []] if tag_str.nil?

    smart_tags = []
    other_tag_ids = []

    tag_str.split(',').map do |t|
      st = TAGS.detect{|smart| smart.name == t} # TODO: only applicable tags for class ?
      st.nil? ? other_tag_ids << t : smart_tags << st
    end
    [smart_tags, other_tag_ids]
  end

  # Wrapper around Tag.find_for_project_and_class.
  # Includes also smart tags to results.
  def self.find_all_tags(project, klass, selected, test_area, selected_smart)

    # TODO refactor in controller
    sel = selected || []
    sel_smart = selected_smart || []

    tags = Tag.find_for_project_and_class(project, klass, selected, test_area,
                                          sel_smart.map{|t| t.conditions(klass, project, test_area)},
                                          sel_smart.map(&:joins))

    return tags unless sel.empty? # smart tags only on root level

    if klass == Case
      smart = TAGS.select do |smart_tag|
        smart_tag != SmartTag::NoLinkedCases and
          smart_tag.filter_allowed(sel, sel_smart) == [sel, sel_smart]
      end
    elsif klass == Requirement
      smart = [SmartTag::Untagged, SmartTag::NoLinkedCases].select do |smart_tag|
        smart_tag.filter_allowed(sel, sel_smart) == [sel, sel_smart]
      end
    else
      smart = []
    end

    (selected_smart || []).each{|s| tags, smart = s.filter_allowed(tags, smart)}

    smart + tags
  end

end
