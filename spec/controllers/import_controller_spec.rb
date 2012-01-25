require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ImportController do
  describe "#doors" do
    it "create a doors import" do
      log_in
      params = {:file                    => 'dummy file',
                :max_object_level        => 10,
                :tags                    => '',
                :simulate                => false,
                :requirement_tag_enabled => true,
                :requirement_tag_level   => 2,
                :requirement_enabled     => true,
                :requirement_min         => 3,
                :requirement_max         => 10,
                :set_enabled             => true,
                :set_level               => 2,
                :case_tag_enabled        => true,
                :case_tag_level          => 2,
                :case_enabled            => true,
                :case_min                => 3,
                :case_max                => 10}

      flexmock(Import::Doors).should_receive(:new).once.with(
        @project.id, @user.id, 'dummy file', Hash).and_return(
          flexmock('doors import', :log => "some log..."))

      post 'doors', params
    end
  end

end
