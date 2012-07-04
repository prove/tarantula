
shared_examples_for "taggable" do
  
  it "should hold tags" do
    @host = get_instance
    t1 = Tag.make! :name => 'tag1', :project => @host.project, :taggable_type => @host.class.to_s
    t2 = Tag.make! :name => 'tag2', :project => @host.project, :taggable_type => @host.class.to_s
    @host.tags << t1
    @host.tags << t2
    @host.tags.count.should == 2    
    @host.tags.find_by_name('tag1').should_not be_nil
    @host.tags.find_by_name('tag2').should_not be_nil
  end
  
  describe "#TaggingExtensions" do
    
    it "#tag_with should add/replace tags" do
      @host = get_instance
      @host.tags.should be_empty
      @host.tag_with('foo,bar')
      @host.reload
      @host.tags.should include(Tag.find_by_name('foo'))
      @host.tags.should include(Tag.find_by_name('bar'))    
      @host.tag_with('bar,baz')
      @host.reload
      @host.tags.should include(Tag.find_by_name('bar'))
      @host.tags.should include(Tag.find_by_name('baz'))
      @host.tags.count.should == 2
    end
    
    it "#tags_to_str should return comma-separated tags list" do
      @host = get_instance
      @host.tag_with('tag1,tag2')
      @host.tags_to_s.should == 'tag1,tag2'      
    end
    
    it "#has_tags? should tell if tags are included" do
      @host = get_instance
      @host.tag_with('tag1,tag2')
      @host.has_tags?([Tag.find_by_name('tag1')]).should == true
      @host.has_tags?([Tag.find_by_name('tag3')]).should == false
    end
    
    it ".find_with_tags should raise if no project given" do
      @host = get_instance
      lambda { @host.class.find_with_tags(nil) }.should raise_error(StandardError, 
                 "give a project for find_with_tags")
    end
    
    it "taggings should be destroyed on destroy" do
      @host = get_instance
      flexmock(@host).should_receive('taggings.destroy_all').once
      @host.destroy
    end
    
  end

end

