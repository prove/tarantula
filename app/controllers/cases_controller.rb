# -*- coding: utf-8 -*-
#require 'ruby-debug'

class CasesController < ApplicationController
  before_filter :only => [:create, :destroy, :update] do |c|
    c.require_permission(['TEST_DESIGNER','MANAGER'])
  end
  before_filter :only => [:index, :show, :change_history] do |c|
    c.require_permission(:any)
  end
  before_filter :get_tags_offset_and_filter, :only => [:index]
  before_filter :case_test_area_permissions, :except => [:index, :create, :destroy]
  before_filter :case_test_area_permissions_multi, :only => [:destroy]
  before_filter :include_users_test_area, :only => [:create, :update]

  #  GET /project/:project_id/cases.tree
  #   Lists cases from the project using ExtJS treeformat for json.
  #
  #  GET /test_sets/:test_set_id/cases
  #   Lists cases from the test set.
  #
  def index
    local_limit = (params[:limit] ? params[:limit].to_i : nil) || Testia::LOAD_LIMIT

    if params[:requirement_id]
      ret = Requirement.find(params[:requirement_id]).cases.map(&:to_tree)
    elsif (params[:test_set_id])
      @test_set = TestSet.find(params[:test_set_id])
      if( params[:allcases])
        ret = @test_set.cases.sort{|a,b| a.position <=> b.position}.
          map{ |c| c.to_data(:brief) }
        ret.compact!
      else
        ret = @test_set.cases
        ret = ret.select{|c| c.title =~ /#{@filter}/} if @filter
        ret = ret.sort{|a,b| a.position <=> b.position }
        # TODO: offset and limit
        ret = ret.map{ |c| c.to_tree.merge(:order => c.position)}
      end
    else
      ret = get_tagged_items(Case)
    end

    render :json => ret
  end

  #  POST /cases
  def create
    # TODO: background task copying, move to its own action
    if params[:project_id] and (params[:case_ids] or params[:tag_ids])
      Case.copy_many_to(params[:project_id],
        {:case_ids       => params[:case_ids],
         :tag_ids        => params[:tag_ids],
         :from_test_area => @current_user.test_area(@project),
         :to_test_areas  => params[:test_area_ids],
         :user           => @current_user,
         :from_project   => @project})

      render :nothing => true, :status => :created
      return
    end

    @data.symbolize_keys!
    steps = @data.delete(:steps).map{|s| s.symbolize_keys}
    tag_list = @data.delete(:tag_list)
    requirements = (@data.delete(:requirements)||[]).map{ |r| Requirement.find(r)}


    @data[:project_id] ||= @project.id
    @data[:created_by] = @data[:updated_by] = @current_user.id

    @case = Case.create_with_steps!(@data, steps, tag_list)
    @case.update_requirements(requirements)

    render :json => @case.id, :status => :created
  end


  # === GET /cases/:id
  #
  #   Return case information.
  #

  def show
    case_data = @case.
      to_data(:include_tag_list, :strict_average_duration).
      merge(:steps => @case.steps.map(&:to_data))

    render :json => {:data => [case_data]}
  end


  # === PUT /cases/:id
  #   Saves changes to the case.
  #
  def update
    if params[:data]
      # Incoming data in json encoded format.
      @data.symbolize_keys!
      @data[:project_id] ||= @project.id
      @data[:updated_by] = @current_user.id

      steps = @data.delete(:steps)
      tag_list = @data.delete(:tag_list)
      ce = @data.delete(:update_case_execution)

      requirements = (@data.delete(:requirements)||[]).map{ |r| Requirement.find(r)}
      @case.update_with_steps!(@data, steps, tag_list, ce)
      @case.update_requirements(requirements)
    else
      # Tag update
      @case.tag_with((@case.tags_to_s+params[:tag_list]).chomp(','))
    end
    render :json => @case.id, :status => :ok
  end

  #  DELETE /cases/:id
  def destroy
    if params[:confirm].blank?
      multi = (@cases.size > 1)
      @cases.each{|c| c.raise_if_delete_needs_confirm(multi)}
    end

    @cases.each{|c| c.toggle_deleted }

    render :json => @cases.map(&:id), :status => :ok
  end

  def change_history
    render :json => @case.change_history
  end

  private

  def case_test_area_permissions
    test_area_permissions(Case, params[:id])
  end

  def case_test_area_permissions_multi
    test_area_permissions(Case, params[:id], true)
  end

end
