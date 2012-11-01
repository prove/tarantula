require "spec_helper"

describe AutomationToolsController do
  describe "routing" do

    it "routes to #index" do
      get("/automation_tools").should route_to("automation_tools#index")
    end

    it "routes to #new" do
      get("/automation_tools/new").should route_to("automation_tools#new")
    end

    it "routes to #show" do
      get("/automation_tools/1").should route_to("automation_tools#show", :id => "1")
    end

    it "routes to #edit" do
      get("/automation_tools/1/edit").should route_to("automation_tools#edit", :id => "1")
    end

    it "routes to #create" do
      post("/automation_tools").should route_to("automation_tools#create")
    end

    it "routes to #update" do
      put("/automation_tools/1").should route_to("automation_tools#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/automation_tools/1").should route_to("automation_tools#destroy", :id => "1")
    end

  end
end
