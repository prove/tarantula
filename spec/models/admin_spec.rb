require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Admin do
  describe "#project_assignments" do
    it "should create missing project assignments" do
      Project.destroy_all # this shouldn't have to be done
      p = Project.make!
      admin = Admin.make!
      admin.project_assignments.map(&:to_data).should == \
        [{:group => 'ADMIN',
          :login => admin.login,
          :deleted => false,
          :test_area => nil,
          :test_area_forced => false,
          :test_object => nil}]
    end
  end
end
