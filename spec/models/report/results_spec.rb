require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::Results do
  def get_instance(opts={})
    return Report::Results.new(1, ["",{}]) if opts[:static]
    
    p = Project.make!
    Report::Results.new(p.id, ["",{}])
  end

  it_behaves_like "cacheable report"
  
  describe ".combine" do
    it "should combine Report::Results" do
      data1 = [{:name => Passed.rep, :test_results => 5, 
                :perc => "50%", :all_cases => '50%'},
               {:name => Failed.rep, :test_results => 5, 
                :perc => "50%", :all_cases => '50%'},
               {:name => Skipped.rep, :test_results => 0, 
                :perc => "0%", :all_cases => '0%'},
               {:name => NotImplemented.rep, :test_results => 0, 
                :perc => "0%", :all_cases => '0%'},
               {:name => NotRun.rep, :test_results => 0, 
                :perc => "0%", :all_cases => '0%'},
               {:name => 'Total', :excl_results => 10, :test_results => "10 (30)",
                :perc => "100%", :all_cases => '100%'}]
                
      data2 = [{:name => Passed.rep, :test_results => 2, 
                :perc => "20%", :all_cases => '20%'},
               {:name => Failed.rep, :test_results => 2, 
                :perc => "20%", :all_cases => '20%'},
               {:name => Skipped.rep, :test_results => 2, 
                :perc => "20%", :all_cases => '20%'},
               {:name => NotImplemented.rep, :test_results => 2, 
                :perc => "20%", :all_cases => '20%'},
               {:name => NotRun.rep, :test_results => 2, 
                :perc => "20%", :all_cases => '20%'},
               {:name => 'Total', :excl_results => 10, :test_results => "10 (45)",
                :perc => "100%", :all_cases => '100%'}]
      
      rep1 = flexmock('Report::Results', :query => true,
                      'tables.first' => flexmock('table', :data => data1))
      rep2 = flexmock('Report::Results', :query => true,
                      'tables.first' => flexmock('table', :data => data2))
      res = Report::Results.combine(['to1', 'to2'], [rep1, rep2])
      h = ActiveSupport::OrderedHash.new
      h[:name] = ''
      h[:part_0] = 'to1'
      h[:part_1] = 'to2'
      res.first.should == h 
        
      res[1].should == \
         [{:name => Passed.rep, :part_0 => 5, :part_1 => 2},
          {:name => Failed.rep, :part_0 => 5, :part_1 => 2},
          {:name => Skipped.rep, :part_0 => 0, :part_1 => 2},
          {:name => NotImplemented.rep, :part_0 => 0, :part_1 => 2},
          {:name => NotRun.rep, :part_0 => 0, :part_1 => 2}]
    end
  end
  
end
