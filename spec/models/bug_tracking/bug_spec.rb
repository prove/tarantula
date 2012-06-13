require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')


describe Bug do
  def get_instance(atts={})
    Bug.make!(atts)
  end

  it_behaves_like "externally_identifiable"

  it "#deleted should always return false" do
    Bug.new.deleted.should == false
  end

  it "#to_data should return required data" do
    bt = Bugzilla.make!
    bug = Bug.make!(:bug_tracker => bt)
    keys = bug.to_data.keys
    keys.should include(:id)
    keys.should include(:name)
    keys.should include(:external_id)
    keys.size.should == 3
  end

  describe ".all_linked" do
    it "should return all bugs linked to steps" do
      bt = Bugzilla.make!(:severities => [BugSeverity.make!],
                          :products => [BugProduct.make!])
      p = Project.make!(:bug_tracker => bt)
      bug = bt.bugs.create!(:external_id => "#{Bug.count}",
                            :severity    => bt.severities.first,
                            :product     => bt.products.first)
      e = Execution.make_with_runs(:project => p)
      e.case_executions.first.step_executions.first.update_attributes!(
        :bug_id => bug.id)
      Bug.all_linked(p).should == [bug]
    end
  end
end
