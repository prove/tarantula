require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

shared_examples_for "api_method" do |method_name|
  def get_basic_auth(user)
    puts user.inspect
    us = user.login
    pw = user.password
    ActionController::HttpAuthentication::Basic.encode_credentials us, pw
  end
  context "unauthorized user" do
    it "returns 403 error via XML" do
      response = post "create_testcase", :request => {}.to_xml,
           :format => :xml, 'HTTP_AUTHORIZATION' =>  "Basic admin:admin"
      puts response.body.inspect
    end
  end

  context "invalid XML provided" do
    it "returns \"Invalid XML provided\" 500 error" do
    end
  end

  context "provided project not found" do
    it "returns \"Project not found\" 500 error" do
    end
  end

end

describe ApiController do
  before :all do
    @user = User.find_by_login('tester')
    @admin = User.find_by_login('admin')
    @project = Project.make!
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
    it_should_behave_like "api_method", "create_testcase"

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

