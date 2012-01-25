require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Tag do
  
  it "#to_tree should return necessary data" do
    data = Tag.new.to_tree.keys
    data.should include(:text)
    data.should include(:dbid)
    data.should include(:leaf)
    data.should include(:cls)
    data.size.should == 4
  end
  
  describe ".find_for_project_and_class" do
    before(:each) do
      flexmock(SmartTag).should_receive(:all).and_return([])
    end
    
    it "should return correct tags when none selected" do
      p = Project.make_with_cases(:cases => 10)
      p.cases[0].tag_with('tag1')
      p.cases[1].tag_with('tag1')
      p.cases[2].tag_with('tag2')
      tags = Tag.find_for_project_and_class(p, Case, nil)
      tags.size.should == 2
      tags.should include(Tag.find_by_name('tag1'))
      tags.should include(Tag.find_by_name('tag2'))
    end
    
    it "should not return tags which are already selected" do
      p = Project.make_with_cases(:cases => 5)
      p.cases[0].tag_with('tag1,tag2')
      p.cases[2].tag_with('tag2')
      tags = Tag.find_for_project_and_class(p, Case, [Tag.find_by_name('tag2')])
      tags.size.should == 1
      tags.should include(Tag.find_by_name('tag1'))
    end
    
    it "should not show unexisting tag combinations" do
      p = Project.make_with_cases(:cases => 3)
      p.cases[0].tag_with('tag1,tag2')
      p.cases[1].tag_with('tag2')
      p.cases[2].tag_with('tag3,tag4')
      tags = Tag.find_for_project_and_class(p, Case, [Tag.find_by_name('tag2')])
      tags.size.should == 1
      tags.should include(Tag.find_by_name('tag1'))
    end
    
    it "should not show tags of deleted items" do
      p = Project.make_with_cases(:cases => 2)
      p.cases[0].tag_with('tag1,tag2')
      p.cases[0].update_attribute(:deleted, 1)
      p.cases[1].tag_with('tag2')
      tags = Tag.find_for_project_and_class(p, Case, [])
      tags.size.should == 1
      tags.should include(Tag.find_by_name('tag2'))
    end
    
    it "should return no tags if deleted is selected" do 
      p = Project.make_with_cases(:cases => 5)
      p.cases[0].tag_with('tag1')
      p.cases[1].tag_with('tag2')
      tags = Tag.find_for_project_and_class(p, Case, 'deleted')
      tags.should be_empty
    end
    
    it "should not return tags used only in other projects" do
      p = Project.make_with_cases(:cases => 1)
      p.cases.first.tag_with('tag1,tag2')
      p2 = Project.make_with_cases(:cases => 1)
      p2.cases.first.tag_with('tag3')
      tags = Tag.find_for_project_and_class(p2, Case, [])
      tags.size.should == 1
      tags.should include(Tag.find_by_name('tag3'))
    end    
  end
  
end
