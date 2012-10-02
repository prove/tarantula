class AutomationToolsController < ApplicationController
  before_filter :only => [:destroy, :create, :update] do |f|
    f.require_permission(['ADMIN'])
  end
  before_filter :only => [:show, :index, :products] do |f|
    f.require_permission(:any)
  end

  def index
    render :json => {:data => AutomationTool.find(:all).map(&:to_tree)}
  end

  def show
    render :json => {:data => AutomationTool.find(params[:id]).to_tree}
  end

  def create
		at = AutomationTool.create(@data)
    render :json => at.id
  end

  def update
    at = AutomationTool.find(params[:id])
    at.update_attributes!(@data)

    render :nothing => true, :status => :ok
  end

  def destroy
    AutomationTool.find(params[:id]).destroy
    render :nothing => true, :status => :ok
  end
end
