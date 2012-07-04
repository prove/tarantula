require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe TestSet do
  def get_instance(atts={})
    ts = TestSet.make!(atts)
    def ts.new_versioned_child
      Case.new(:title => 'a case', :position => rand(100)+1,
               :project => self.project, :date => Date.today)
    end
    def ts.versioned_assoc_name; 'cases'; end
    ts
  end
  
  it_behaves_like "taggable"
  it_behaves_like "versioned"
  it_behaves_like "externally_identifiable"
  it_behaves_like "date stamped"
  it_behaves_like "prioritized"
  
  describe "#to_data" do
    it "should return necessary data" do
      data = TestSet.make!.to_data
      data.should have_key('name')
      data.should have_key('date')
      data.should have_key('updated_at')
      data.should have_key('project_id')
      data.should have_key('created_by')
      data.should have_key('updated_by')
      data.should have_key('id')
      data.should have_key('version')
      data.should have_key('deleted')
      data.should have_key('archived')
      data.should have_key('created_at')
      data.should have_key('average_duration')
      data.should have_key('priority')
      data.should have_key('test_area_ids')
      data.keys.size.should == 14
    end
  
    it "should return necessary data [brief mode]" do
      data = TestSet.make!.to_data(:brief)
      data.should have_key(:name)
      data.should have_key(:id)
      data.should have_key(:date)
      data.should have_key(:version)
      data.should have_key(:tag_list)
      data.should have_key(:deleted)
      data.should have_key(:archived)
      data.should have_key(:average_duration)
      data.should have_key(:priority)
      data.should have_key(:test_area_ids)
      data.keys.size.should == 10
    end
  end
  
  it "#to_tree should return necessary data" do
    data = TestSet.make!.to_tree
    data.should have_key(:text)
    data.should have_key(:leaf)
    data.should have_key(:dbid)
    data.should have_key(:deleted)
    data.should have_key(:archived)
    data.should have_key(:cls)
    data.should have_key(:tags)
    data.keys.size.should == 7
  end
  
  it ".create_with_cases! should create a test set with cases" do
    a_case = flexmock('case')
    a_case.should_receive(:position=).once.with(1)
    case_assoc = flexmock('case assoc')
    case_assoc.should_receive(:<<).once.with([a_case])
    ts = flexmock('test set', :cases => case_assoc)
    ts.should_receive(:tag_with).once.with('a_tag')
    
    flexmock(Case).should_receive(:find).once.with(1).and_return(a_case)
    flexmock(TestSet).should_receive(:create!).once.with({'att' => 'val'}).\
      and_return(ts)
    
    TestSet.create_with_cases!({'att' => 'val'}, [1], 'a_tag')
  end
  
  it "#update_with_cases! should update with cases" do
    cases_assoc = flexmock('cases assoc')
    ts = flexmock(TestSet.new, :cases => cases_assoc)
    ts.should_receive(:update_attributes!).once.with({'att' => 'val'})
    ts.should_receive(:tag_with).once.with('a_tag')
    a_case = flexmock('case')
    flexmock(Case).should_receive(:find).once.with(1).and_return(a_case)
    a_case.should_receive(:position=).with(1).once
    cases_assoc.should_receive(:<<).once.with([a_case])
    
    ts.update_with_cases!({'att' => 'val'}, [1], 'a_tag')
  end
  
end
