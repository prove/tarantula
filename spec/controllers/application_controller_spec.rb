require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ApplicationController do
  # TODO: spec differently
  describe "#get_tagged_items" do
    it "should limit to at most LOAD_LIMIT of items" do
      log_in(:admin => false)
      controller.instance_variable_set(:@offset, 0)

      flexmock(Project).should_receive(:find).and_return(flexmock('project', :id => 1))
      flexmock(Tag).should_receive(:find_for_project_and_class).and_return([]) # no tags
      flexmock(Case).should_receive(:find_with_tags).and_return([])

      tagged_items = controller.instance_eval{ get_tagged_items(Case) }

      # When finding smart tags for Cases "NoLinkedCases" is not included
      controller.instance_variable_get(:@i_limit).should == Testia::LOAD_LIMIT - (SmartTag::TAGS.size-1)
      controller.instance_variable_get(:@i_offset).should == 0
    end

    it "should reduce item limit by number of tags when no offset" do
      log_in(:admin => false)
      num_tags = Testia::LOAD_LIMIT - (Testia::LOAD_LIMIT / 2)
      controller.instance_variable_set(:@offset, 0)

      flexmock(Project).should_receive(:find).and_return(flexmock('project', :id => 1))
      flexmock(Tag).should_receive(:find_for_project_and_class).and_return(
        [flexmock('tag mock', :to_tree => 'mock tag tree')] * num_tags)
      flexmock(Case).should_receive(:find_with_tags).and_return([])

      tagged_items = controller.instance_eval{ get_tagged_items(Case) }

      # When finding smart tags for Cases "NoLinkedCases" is not included
      controller.instance_variable_get(:@i_limit).should == \
        Testia::LOAD_LIMIT - num_tags - (SmartTag::TAGS.size-1)
      controller.instance_variable_get(:@i_offset).should == 0
    end

    it "should offset properly when tags and offset present" do
      log_in(:admin => false)
      num_tags = Testia::LOAD_LIMIT - (Testia::LOAD_LIMIT / 2)
      os = controller.instance_variable_set(:@offset, 5)

      flexmock(Project).should_receive(:find).and_return(flexmock('project', :id => 1))
      flexmock(Tag).should_receive(:find_for_project_and_class).and_return(
        [flexmock('tag mock', :to_tree => 'mock tag tree')] * num_tags)
      flexmock(Case).should_receive(:find_with_tags).and_return([])

      tagged_items = controller.instance_eval{ get_tagged_items(Case) }

      controller.instance_variable_get(:@i_limit).should == \
        Testia::LOAD_LIMIT
      # When finding smart tags for Cases "NoLinkedCases" is not included
      controller.instance_variable_get(:@i_offset).should == \
        (Testia::LOAD_LIMIT * os) - num_tags - (SmartTag::TAGS.size-1)
    end

  end

  describe "#test_area_permissions" do
    it "should raise if no test area permissions" do
      log_in
      req = Requirement.make!
      ta = flexmock('test area', :forced => true,
                    :name => 'ta', :project_id => req.project_id,
                    :requirement_ids => [])

      flexmock(Requirement).should_receive(:find).once.and_return(req)
      flexmock(@user).should_receive(:test_area).once.and_return(ta)
      flexmock(controller).should_receive(:params).and_return({:id => 1})

      lambda {controller.instance_eval { test_area_permissions(Requirement, req.id) }}.\
        should raise_error(StandardError, "Permission denied! (test area). Please refresh your browser.")
    end

    it "should return true if test area permissions ok" do
      log_in
      req = flexmock(Requirement.make!)
      ta = flexmock('test area', :forced => true,
                    :name => 'ta', :project_id => req.project_id,
                    :requirement_ids => [req.id])
      ta_tag = flexmock('test area tag')
      flexmock(Requirement).should_receive(:find).once.and_return(req)
      flexmock(@user).should_receive(:test_area).once.and_return(ta)
      flexmock(controller).should_receive(:params).and_return({:id => 1})

      controller.instance_eval { test_area_permissions(Requirement, req.id) }.\
        should == true
    end

    it "should return true if no forced test area" do
      log_in
      req = Requirement.make!
      ta = flexmock('test area', :forced => false,
                    :name => 'ta', :project_id => req.project_id)
      flexmock(Requirement).should_receive(:find).once.and_return(req)
      flexmock(@user).should_receive(:test_area).once.and_return(ta)
      flexmock(controller).should_receive(:params).and_return({:id => 1})

      controller.instance_eval { test_area_permissions(Requirement, req.id) }.\
        should == true
    end
  end
end
