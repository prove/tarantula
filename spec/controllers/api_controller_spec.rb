require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')
require 'faker'
require 'builder'

def encode_credentials(u,p)
	ActionController::HttpAuthentication::Basic.encode_credentials(u,p)
end

def create_testcase_body(project=@project.name, title=@testcase.title, priority='high', tags='tag1,tag2', objective='test objective', test_data='test data', preconditions='test preconditions', steps=[{:action => 'a1', :result => 'r1'}, {:action => 'a2', :result => 'a2'}])
#<request>
#   <testcase project="Poect 0" title="add" priority="high" tags="func" objective="32" data="322" preconditions="123">
#   	<step action="1" result="1"></step>
#   	<step action="2" result="2"></step>
#   </testcase>
#</request>
	builder = Builder::XmlMarkup.new
	xml = builder.request { |r| 
		r.testcase({ :project => project, :title => title, :priority => priority, :tags => tags, :objective => objective, :data => test_data, :preconditions => preconditions }){ |tc|
			steps.each{|step|
				tc.step(step)
			}
		}			
 	}
end

def update_testcase_execution_body(project=@project.name, execution=@execution.name, testcase=@testcase.title, step_position=1, result='PASS', comments='step comments', duration='1')
# <request>
#     <project>My project</project>
#     <execution>My execution</execution>
#     <testcase>My testcase</testcase>
#     <duration>1</duration>
#     <step position="2" result="NOT_IMPLEMENTED"></step>
# </request>
	builder = Builder::XmlMarkup.new
	xml = builder.request { |r| 
		r.project(project)
		r.execution(execution)
		r.testcase(testcase)
		r.duration(duration)
		2.times do # this is a hack - update the same step twice to get correct XML structure
			r.step({:position => step_position, :result => result, :comment => comments})
		end
 }
end

def block_or_unblock_testcase_body(project=@project.name, execution=@execution.name, testcase=@testcase.title)
# <request>
#     <project>My project</project>
#     <execution>My execution</execution>
#     <testcase>My testcase</testcase>
# </request>
	builder = Builder::XmlMarkup.new
	xml = builder.request { |r| 
		r.project(project)
		r.execution(execution)
		r.testcase(testcase)
 	}
end

shared_examples_for "api_method" do |method_name|
=begin
context "unauthorized user" do
    it "returns Access denied" do
    	request.env['HTTP_AUTHORIZATION'] = encode_credentials('unauthorized user', 'password')
    	request.env['RAW_POST_DATA'] =  { :request => {} }.to_xml
      	resp = post method_name
    	resp.body.strip.should eq "HTTP Basic: Access denied."
    end
  end



  context "invalid XML provided" do  	
    it "returns \"Invalid XML provided\" 500 error" do    	
    	request.env['RAW_POST_DATA'] =  { :request => {} }.to_xml
	  	post method_name
	  	response.body.should =~ /COULD NOT PARSE REQUEST AS XML/
    end
  end
=end


  context "provided project not found" do
    it "returns \"Project not found\" 500 error" do    	
    	puts eval method_name.to_s + "_body(@project.name + \'whible\')"
    	request.env['RAW_POST_DATA'] = eval method_name.to_s + "_body(@project.name + \'whible\')"
    	resp = post method_name
    	resp.body.should =~ /PROJECT NOT FOUND/
    end
  end




end

describe ApiController do
  	before :all do  	
	    @user = User.create!(
	    	:login => Faker::Internet.user_name, 
	    	:realname => Faker::Name.name, 
	    	:email => Faker::Internet.email, 
	    	:phone => '', 
	    	:admin => true, 
	    	:password => 'password', 
	    	:password_confirmation => 'password'
	   	)    
	    @project = Project.first
	    @user.project_assignments.create!(:project => @project, :group => 'TEST_DESIGNER')    
	    @to = TestObject.find_by_name('test_object_name') || TestObject.create!(:name => 'test_object_name', :project_id => @project.id, :date => "2013-02-26T00:00:00")
	    @execution = Execution.find_by_name('execution_name') || Execution.create!(:name => 'exec_name', :test_object_id => @to.id, :project_id => @project.id, :date => "2013-02-26T00:00:00")
	    @testcase = Case.find_by_title('testcase_title') || Case.create!(:title => 'testcase_title', :created_by => 1, :project_id => 287, :date => "2013-02-26T00:00:00")
	end

	before(:each) do
	  request.env['HTTP_AUTHORIZATION'] = encode_credentials(@user.login, @user.password)
	  request.env['content_type'] = 'application/xml' 
	end   

  describe "#create_testcase" do
=begin
    <request>
    <testcase project="calculon" title="add" priority="high" tags="func" objective="32" data="322" preconditions="123">
    <step action="1" result="1"></step>
    <step action="2" result="2"></step>
    </testcase>
    </request>
=end
    it_should_behave_like "api_method", :create_testcase

=begin
    context "incorrect parameters" do
      it "returns nit-title error as XML" do
      end

      it "returns priority error as XML" do
      end

      it "returns nit-title error as XML" do
      end
    end

    context "correct parameters" do
      it "creates test with 0 steps" do
      end

      it "creates test with 5 steps" do
      end
    end
=end
  end
end

