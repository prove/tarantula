require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require "#{Rails.root}/lib/attsets/spec/shared/attachment_host_spec"


describe Requirement do
  def get_instance(atts={})
    r = Requirement.make!(atts)
    def r.new_versioned_child
      Case.new(:project => Project.last, :title => 'child case', :date => Date.today)
    end
    def r.versioned_assoc_name; 'cases'; end
    r
  end
  
  it_behaves_like "attachment host"
  it_behaves_like "taggable"
  it_behaves_like "externally_identifiable"
  it_behaves_like "date stamped"
  it_behaves_like "versioned"
  
  it "#to_data should return necessary data" do
    keys = Requirement.new.to_data.keys
    keys.should include(:name)
    keys.should include(:date)
    keys.should include(:description)
    keys.should include(:priority)
    keys.should include(:optionals)
    keys.should include(:id)
    keys.should include(:external_id)
    keys.should include(:deleted)
    keys.should include(:archived)
    keys.should include(:created_at)
    keys.should include(:updated_at)
    keys.should include(:tag_list)
    keys.should include(:test_area_ids)
    keys.size.should == 13
  end
  
  it "#to_tree should return necessary data" do
    keys = Requirement.new.to_tree.keys
    keys.should include(:text)
    keys.should include(:leaf)
    keys.should include(:dbid)
    keys.should include(:deleted)
    keys.should include(:archived)
    keys.should include(:cls)
    keys.should include(:tags)
    keys.size.should == 7
  end
  
  it "should .create_with_cases!" do
    cases = flexmock('cases')
    cases.should_receive(:uniq).once.and_return(cases)
    cases_assoc = flexmock('cases association')
    cases_assoc.should_receive(:<<).once.with(cases)
    new_req = flexmock('requirement', :cases => cases_assoc)
    new_req.should_receive(:tag_with).once.with('tag_list')
    
    flexmock(Requirement).should_receive(:create!).with('att_hash').once.\
      and_return(new_req)
    
    Requirement.create_with_cases!('att_hash', cases, 'tag_list')
  end
  
  it "should #update_with_cases!" do
    req = flexmock(Requirement.new)
    cases = flexmock('cases')
    cases.should_receive(:uniq).once.and_return(cases)
    cases_assoc = flexmock('cases assoc')
    cases_assoc.should_receive(:<<).once.with(cases)
    req.should_receive(:cases).and_return(cases_assoc)
    req.should_receive(:tag_with).once.with('tags')
    req.should_receive(:update_attributes!).once.with('atts')
    
    req.update_with_cases!('atts', cases, 'tags')
  end
  
  it "should keep earlier version's cases with #update_keeping_cases" do
    req = Requirement.make!
    case1 = Case.make!
    case2 = Case.make!
    req.cases << case1 << case2
    req.cases.should == [case1, case2]
    req.version.should == 1
    req.update_keeping_cases(:name => 'updated')
    req.version.should == 2
    req.reload.cases.should == [case1, case2]
  end
  
  describe "#cases_on_test_area" do
    it "should return [] if no cases belonging to test area" do
      p = Project.make!
      ta = TestArea.make!(:project => p)
      req = Requirement.make!(:project => p)
    
      req.cases_on_test_area(ta).should == []
    end
    
    it "should return cases belonging to test area" do
      p = Project.make!
      ta = TestArea.make!(:project => p)
      c = Case.make!(:project => p, :test_areas => [ta])
      req = Requirement.make!(:project => p)
      req.cases << c
      
      req.cases_on_test_area(ta).should == [c]
    end
    
    it "should not return cases that don't belong to test area" do
      p = Project.make!
      ta = TestArea.make!(:project => p)
      c = Case.make!(:project => p)
      req = Requirement.make!(:project => p)
      req.cases << c
      
      req.cases_on_test_area(ta).should == []
    end
  end
  
  describe ".id_sort!" do
    it "should return [] if empty array given" do
      Requirement.id_sort!([]).should == []
    end
    
    it "should return [req] if only req given" do
      r = Requirement.make!
      Requirement.id_sort!([r]).should == [r]
    end
    
    it "should sort if external_id number" do
      r1 = Requirement.make!(:external_id => "5")
      r2 = Requirement.make!(:external_id => "3")
      Requirement.id_sort!([r1,r2]).should == [r2,r1]      
    end
    
    it "should sort pure numbers before mixed's" do
      r1 = Requirement.make!(:external_id => "REQ03")
      r2 = Requirement.make!(:external_id => "5")
      Requirement.id_sort!([r1,r2]).should == [r2,r1]
    end
    
    it "should sort mixeds [1]" do
      r1 = Requirement.make!(:external_id => "REQ03")
      r2 = Requirement.make!(:external_id => "REQ05")
      Requirement.id_sort!([r1,r2]).should == [r1,r2]
    end
    
    it "should sort mixeds [2]" do
      r1 = Requirement.make!(:external_id => "REQ03")
      r2 = Requirement.make!(:external_id => "FP1")
      r3 = Requirement.make!(:external_id => "REQ05")
      Requirement.id_sort!([r1,r2,r3]).should == [r2,r1,r3]
    end
    
    it "should sort numbers and mixeds" do
      r1 = Requirement.make!(:external_id => "100")
      r2 = Requirement.make!(:external_id => "54")
      r3 = Requirement.make!(:external_id => "REQ100")
      r4 = Requirement.make!(:external_id => "REQ21")
      r5 = Requirement.make!(:external_id => "FP01")
      Requirement.id_sort!([r1,r2,r3,r4,r5]).should == [r2,r1,r5,r4,r3]
    end
    
  end
end
