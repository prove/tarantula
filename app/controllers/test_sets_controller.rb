# -*- coding: utf-8 -*-

class TestSetsController < ApplicationController

  before_filter :only => [:create, :destroy, :update] do |f|
    f.require_permission(['TEST_DESIGNER','MANAGER'])
  end
  before_filter :only => [:index, :show] do |f|
    f.require_permission(:any)
  end

  before_filter :get_tags_offset_and_filter, :only => [:index]
  before_filter :test_set_test_area_permissions, :except => [:index, :create]
  before_filter :include_users_test_area, :only => [:create, :update]
  
  # GET /test_sets
  def index
    if params[:project_id]      
      active = get_tagged_items(TestSet, 
        {:include_tags => false, :conditions => 'deleted=0', :conv_method => :to_data})
      
      render :json => {:data => active }
      return
    end
    
    render :json => get_tagged_items(TestSet)
  end

  # POST /test_sets
  def create
    @data.symbolize_keys!
    tag_list = @data.delete(:tag_list)
    case_data = @data.delete(:cases)
    @data[:project_id] = @project.id
    @data[:created_by] = @data[:updated_by] = @current_user.id
    
    @set = TestSet.create_with_cases!(@data, case_data, tag_list)
    
    render :json => @set.id, :status => :created
  end

  # GET /test_sets/:id
  def show
    render :json => {:data => [ @test_set.to_data(:brief) ]}
  end

  # PUT /test_sets/:id
  def update
    @data.symbolize_keys!
    tag_list = @data.delete(:tag_list)
    case_data = @data.delete(:cases)
    @data[:project_id] = @project.id if @data[:project_id].nil?
    @data[:updated_by] = @current_user.id
    
    @test_set.update_with_cases!(@data, case_data, tag_list)
    
    render :json => @test_set.id, :status => :ok    
  end

  # DELETE /test_sets/:id
  def destroy
    @test_set.deleted = !@test_set.deleted
    @test_set.archived = false
    @test_set.save_without_revision!
    
    render :json => @test_set.id, :status => :ok       
  end

  private

  def test_set_test_area_permissions
    test_area_permissions(TestSet, params[:id])
  end
end
