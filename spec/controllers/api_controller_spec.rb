require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')
require 'faker'
require 'builder'

def encode_credentials(u,p)
	ActionController::HttpAuthentication::Basic.encode_credentials(u,p)
end

def create_testcase_body(
  project=@project.name, 
  title=@testcase.title, 
  priority='high', 
  tags='tag1,tag2', 
  objective='test objective', 
  test_data='test data', 
  preconditions='test preconditions', 
  steps=[{:action => 'a1', :result => 'r1'}, {:action => 'a2', :result => 'a2'}]
)
#<request>
#   <testcase project="Poect 0" title="add" priority="high" tags="func" objective="32" data="322" preconditions="123">
#   	<step action="1" result="1"/>
#   	<step action="2" result="2"/>
#   </testcase>
#</request>
{"request" =>
	{"testcase"=>
    {
      "project" => project, 
      "title"=> title, 
      "priority"=> priority, 
      "tags"=> tags, 
      "objective"=> objective, 
      "data"=> test_data, 
      "preconditions"=> preconditions, 
      "step"=> steps
    }
  }
}
end

def update_testcase_execution_body(
  project=@project.name, 
  execution=@execution.name, 
  testcase=@testcase.title, 
  duration='1', 
  steps=[{:position => 1, :result => 'PASSED'}]
)
# <request>
#     <project>My project</project>
#     <execution>My execution</execution>
#     <testcase>My testcase</testcase>
#     <duration>1</duration>
#     <step position="2" result="NOT_IMPLEMENTED"></step>
# </request>
{"request" =>
  {
    "project" => project, 
    "execution" => execution, 
    "testcase" => testcase, 
    "duration" => duration,
    "step" => steps
  }
}
end

def block_or_unblock_testcase_body(
  project=@project.name, 
  execution=@execution.name, 
  testcase=@testcase.title
)
# <request>
#     <project>My project</project>
#     <execution>My execution</execution>
#     <testcase>My testcase</testcase>
# </request>	
  {"request" =>
    {
      "project" => project, 
      "execution" => execution, 
      "testcase" => testcase,     
    }
  }
end

alias :unblock_testcase_execution_body :block_or_unblock_testcase_body
alias :unblock_testcase_execution_body :block_or_unblock_testcase_body
alias :block_testcase_execution_body :block_or_unblock_testcase_body

shared_examples_for "api_method" do |method_name|

  context "unauthorized user" do
      it "returns Access denied" do
      	request.env['HTTP_AUTHORIZATION'] = encode_credentials('unauthorized user', 'password')
      	post method_name
      	response.body.strip.should eq "HTTP Basic: Access denied."
      end
    end

  context "invalid XML provided" do  	
    it "returns \"Invalid XML provided\" 500 error" do    	
     	request.env['RAW_POST_DATA'] =  { :request => {} }.to_xml
    	post method_name
    	response.body.should =~ /COULD NOT PARSE REQUEST AS XML/
    end
  end

  context "provided project not found" do
    it "returns \"Project not found\" 500 error" do    	
    	post method_name, eval(method_name.to_s + "_body('whible')")
      response.body.should =~ /PROJECT NOT FOUND/
    end
  end
end

describe ApiController do  
	before :all do  	
    tc_title = Faker::Name.name
    ex_title = Faker::Name.name
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
    @testcase = Case.create_with_dummy_step(:title => tc_title+' dummy', :created_by => @user.id, :updated_by => @user.id, 
      :project_id => @project.id, :date => "2013-02-26T00:00:00")
    @testcase_2steps = Case.create_with_steps!({:title => tc_title+' 2 steps', :created_by => @user.id, :updated_by => @user.id, 
      :project_id => @project.id, :date => "2013-02-26T00:00:00"}, [{:action => 'a1', :result => 'r1', :position => 1},{:action => 'a2', :result => 'r2', :position => 2}])
    @execution = Execution.create_with_assignments!({:name => ex_title, :test_object_id => @to.id, 
      :project_id => @project.id, :date => "2013-02-26T00:00:00"}, [@testcase, @testcase_2steps], @user.id)       
  end

  before(:each) do
    request.env['HTTP_AUTHORIZATION'] = encode_credentials(@user.login, @user.password)	  
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


    context "incorrect parameters" do
      it "raps to blank test title" do
        post 'create_testcase', create_testcase_body(@project.name, '')
        response.body.should eq "Validation failed: Title can't be blank"
      end

      it "raps to invalid priority" do
        post 'create_testcase', create_testcase_body(@project.name, @testcase.title, 'not existing priority')
        response.body.should =~ /Invalid priority 'not existing priority'/
      end

      it "raps to empty steps set" do
        post 'create_testcase', create_testcase_body(@project.name, @testcase.title, 'high',nil,nil,nil,nil,nil)
        response.body.should =~ /PROVIDED STEPS SET IS EMPTY/
      end
    end

    context "correct parameters" do
      it "creates test with 0 steps" do
        title = Faker::Name.name        
        post 'create_testcase', create_testcase_body(@project.name, title, 'high',nil,nil,nil,nil,[])        
        response.body.should =~ /testcase #{title} created/
      end

      it "creates test with 5 steps" do
        title = Faker::Name.name
        def step(i); { "action" => "a#{i}", "result" => "r#{i}" }; end
        steps = []
        5.times{ |i| steps << step(i) }
        post 'create_testcase', create_testcase_body(@project.name, title, 'high',nil,nil,nil,nil,steps)
        
        response.body.should =~ /testcase #{title} created/
      end
    end
  end

  describe "#update_testcase_execution" do
=begin
<request>
  <project>calculator</project>
  <execution>CALC</execution>
  <testcase>2+2=4</testcase>
  <duration>1</duration>
  <step position="2" result="NOT_IMPLEMENTED" comment="some text"></step>
  <step position="3" result="PASSED"></step>
</request>
=end
    it_should_behave_like "api_method", :update_testcase_execution

    context "incorrect parameters" do
      # execution=@execution.name, testcase=@testcase.title, duration='1', steps=[{:position => '1', :result => 'PASSED'}, {:position => '2', :result => 'FAILED'}]
      it "raps to invalid execution title" do
        post 'update_testcase_execution', update_testcase_execution_body(@project.name, 'unknown_execution')
        response.body.should =~ /CASEEXECUTION NOT FOUND/
      end

      it "raps to invalid case title" do
        post 'update_testcase_execution', update_testcase_execution_body(@project.name, @execution.name, 'unknown_testcase')
        response.body.should =~ /CASEEXECUTION NOT FOUND/
      end

      it "raps to invalid steps array" do
        post 'update_testcase_execution', update_testcase_execution_body(@project.name, @execution.name, @testcase.title, '1', [1,23,4])
        response.body.should =~ /CASE STEP WITH POSITION \d+ NOT FOUND/
      end

      it "raps to invalid result" do
        post 'update_testcase_execution', update_testcase_execution_body(@project.name, @execution.name, @testcase.title, '1', 
          [{:position => '1', :result => 'WHIBLE'}])
        response.body.should =~ /Invalid result type WHIBLE!/
      end

    end

    context "correct parameters" do
      it "updates test with 1 step" do
        post 'update_testcase_execution', update_testcase_execution_body
        response.body.should =~ /execution #{@execution.name} updated/
      end

      it "updates test with 2 steps" do
        post 'update_testcase_execution', update_testcase_execution_body(@project.name, @execution.name, @testcase_2steps.title, '1', 
          [{:position => '1', :result => 'PASSED'}, {:position => '2', :result => 'FAILED'}])
        response.body.should =~ /execution #{@execution.name} updated/
      end
    end
  end

  describe "#(un)block_testcase_execution" do
=begin
<request>
  <project>My project</project>
  <execution>My execution</execution>
  <testcase>My testcase</testcase>
</request>
=end
    it_should_behave_like "api_method", :block_testcase_execution
    it_should_behave_like "api_method", :unblock_testcase_execution

    context "incorrect parameters" do
      it "raps to invalid execution name or testcase title" do
        post 'block_testcase_execution', block_or_unblock_testcase_body(@project.name, 'unknown_execution')
        response.body.should =~ /CASE EXECUTION NOT FOUND/
        post 'block_testcase_execution', block_or_unblock_testcase_body(@project.name, @execution.name, 'unknown testcase')
        response.body.should =~ /CASE EXECUTION NOT FOUND/
        post 'unblock_testcase_execution', block_or_unblock_testcase_body(@project.name, 'unknown_execution')
        response.body.should =~ /CASE EXECUTION NOT FOUND/
        post 'unblock_testcase_execution', block_or_unblock_testcase_body(@project.name, @execution.name, 'unknown testcase')
        response.body.should =~ /CASE EXECUTION NOT FOUND/
      end
    end

    context "correct parameters" do
      it "updates case execution :blocked parameter to flag" do
        flag = 1
        post 'block_testcase_execution', block_or_unblock_testcase_body
        response.body.should =~ /execution #{@execution.name} blocked/
        flag = 0
        post 'unblock_testcase_execution', block_or_unblock_testcase_body
        response.body.should =~ /execution #{@execution.name} unblocked/
      end
    end
  end
end

