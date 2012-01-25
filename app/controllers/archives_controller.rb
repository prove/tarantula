class ArchivesController < ApplicationController
  before_filter :get_resource_class
  
  # unarchive resources with params[:ids] (csv)
  def destroy
    set_archived(@resource_class, params[:ids], false)
    render :nothing => true, :status => :ok
  end
  
  # archive resources with params[:ids] (csv)
  def create
    set_archived(@resource_class, params[:ids], true)
    render :nothing => true, :status => :ok
  end
  
  private
  
  def set_archived(klass, ids, val)
    klass.transaction do
      resources = klass.find(:all, 
        :conditions => {:id => ids.split(','), :project_id => params[:project_id]})
      
      resources.each do |res|
        res.archived = val
        res.deleted = false
        if res.respond_to?(:save_without_revision!)
          res.save_without_revision!
        else
          res.save!
        end
      end
    end
  end
  
  def get_resource_class
    @resource_class = params[:resources].singularize.classify.constantize
  end
  
end
