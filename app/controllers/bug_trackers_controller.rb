# -*- coding: utf-8 -*-
=begin rdoc


=end

class BugTrackersController < ApplicationController
  before_filter :only => [:destroy, :create, :update] do |f|
    f.require_permission(['ADMIN'])
  end
  before_filter :only => [:show, :index, :products] do |f|
    f.require_permission(:any)
  end

  def index
    render :json => {:data => BugTracker.find(:all).map(&:to_tree)}
  end

  def show
    render :json => {:data => BugTracker.find(params[:id]).to_data}
  end

  def create
    if @data["type"] == "Bugzilla"
      # FIXME: Bugzilla implementation is hard coded for mysql
      @data.delete_if {|k,v| k.match(/adapter/)}
      tracker = Bugzilla.create!(@data)
    elsif @data["type"] == "Jira"
      source = ImportSource.create!({
                                      :adapter => @data['db_adapter'],
                                      :host => @data['db_host'],
                                      :port => @data['db_port'],
                                      :database => @data['db_name'],
                                      :username => @data['db_user'],
                                      :password => @data['db_passwd'],
                                      :name => 'Jira connection'
                                    })
      @data.delete_if {|k,v| k.match(/^db_/)}
      @data[:import_source] = source
      tracker = Jira.create!(@data)

    else
      raise "Tracker type must be specified"
    end

    render :json => tracker.id
  end

  def update
    bt = BugTracker.find(params[:id])

    if bt[:type] == "Jira"
      mapping = {
        'db_adapter' => 'adapter',
        'db_host' => 'host',
        'db_port' => 'port',
        'db_name' => 'database',
        'db_user' => 'username',
        'db_passwd' => 'password'
      }
      src_data = {}
      @data.each do |k,v|
        src_data[mapping[k]] = v if mapping.key?(k)
      end
      bt.import_source.update_attributes!(src_data)
      @data.delete_if {|k,v| k.match(/^db_/)}
    else
      # FIXME: Bugzilla implementation is hard coded for mysql
      @data.delete_if {|k,v| k.match(/adapter/)}
      # Set sync_project_with_classification setting to false if value
      # is not given
      @data['sync_project_with_classification'] ||= false
    end
    bt.update_attributes!(@data)

    render :nothing => true, :status => :ok
  end

  def destroy
    BugTracker.find(params[:id]).destroy
    render :nothing => true, :status => :ok
  end

  # /projects/:project_id/bug_trackers/:id/products
  def products
    project = Project.find_by_id(params[:project_id])
    bt = BugTracker.find(params[:id])
    bt.refresh!
    prods = bt.products_for_project(project, params[:project_name])
    render :json => {:data => prods}
  end

end
