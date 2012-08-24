# -*- coding: utf-8 -*-

class ReportController < ApplicationController
  before_filter :except => [:dashboard] do |c|
    c.require_permission(['TEST_DESIGNER','MANAGER','ADMIN',
                          'MANAGER_VIEW_ONLY'])
  end
  before_filter :only => :dashboard do |c|
    c.require_permission(:any)
  end

  ### DASHBOARD ###############################################################
  def dashboard
    @pa = @current_user.project_assignments.find_by_project_id(@project.id)
    @report = Report::Dashboard.new(@current_user.id, @project.id,
                                    @current_user.test_area(@project).try(:id),
                                    @pa.try(:test_object_id))

    if Rails.cache.exist?(@report.cache_key) or Rails.env == 'development'
      render :json => @report
    else
      @report.send_later(:query)
      render :nothing => true, :status => 202 # accepted
    end
  end
  #############################################################################

  def test_result_status
    ta = @current_user.test_area(@project)

    if params[:test_object_ids]          # 1)
      to_id = get_ids(:test_object).first
      @report = Report::TestResultStatus.new(@project.id, ta.try(:id), to_id)
    else
      raise "invalid parameters"
    end

    respond_to_formats
  end

  def results_by_test_object
    ta = @current_user.test_area(@project)

    @report = Report::ResultsByTestObject.new(
      @project.id, get_ids(:test_object),
      params[:piorities].split(',').map(&:to_i), ta.try(:id))

    respond_to_formats
  end

  def case_execution_list
    ta = @current_user.test_area(@project)

    opts = [@project.id]
    if params[:test_object_ids]
      opts << get_ids(:test_object)
      opts << nil
    elsif params[:execution_ids]
      opts << nil
      opts << get_ids(:execution)
    else
      raise "invalid parameters"
    end

    if params[:tags]
      opts << true
    else
      opts << false
    end

    opts << ta.try(:id)
    opts << params[:sort_by]
    opts << params[:sort_dir]

    @report = Report::CaseExecutionList.new(*opts)
    respond_to_formats
  end

  def test_efficiency
    ta = @current_user.test_area(@project)
    opts = [@project.id, ta.try(:id)]

    if params[:test_object_ids]
      opts << get_ids(:test_object)
    else
      opts += [nil, Date.parse(params[:sdate]), Date.parse(params[:edate])]
    end

    @report = Report::TestEfficiency.new(*opts)
    respond_to_formats
  end

  def status
    ta = @current_user.test_area(@project)
    @report = Report::Status.new(
      @project.id, get_ids(:test_object), ta ? ta.id : nil)
    respond_to_formats
  end

  def requirement_coverage
    ta = @current_user.test_area(@project)
    @report = Report::RequirementCoverage.new(@project.id, ta.try(:id),
                                              params[:sort_by], false,
                                              get_ids(:test_object))
    respond_to_formats
  end

  def bug_trend
    ta = @current_user.test_area(@project)
    @report = Report::BugTrend.new(@project.id, ta.try(:id))
    respond_to_formats
  end

  def workload
    @report = Report::Workload.new(@project.id)
    respond_to_formats
  end

  private

  def get_ids(id_type)
    key = "#{id_type}_ids".to_sym
    value = params[key]
    raise "No #{id_type.to_s.humanize.downcase} selected!" if value.blank?
    value.split(',').map(&:to_i).sort
  end

  def respond_to_formats
    @report.query

    respond_to do |format|
      format.json do
        char = params.keys.size > 2 ? '&' : '?'
        @report.meta.pdf_export_url = url_for({
                                                :controller => 'report',
                                                :format => 'pdf',
                                                :only_path => true
                                              }.merge(params))
        @report.meta.spreadsheet_export_url = url_for({
                                                        :controller => 'report',
                                                        :format => 'xls',
                                                        :only_path => true
                                                      }.merge(params))
        @report.tables.csv_export_url = url_for({
                                                  :controller => 'report',
                                                  :format => 'csv',
                                                  :only_path => true
                                                }.merge(params))
        # We provide Url definitions as Hashes so that Report:Base can
        # add proper cache key parameters to urls and use url_for
        # helper later see Report::Base.data_post_url=
        @report.data_post_url = {
          :controller => 'report_data',
          :action => :index,
          :only_path => true,
          :project_id => @project.id,
          :user_id => @current_user.id
        }
        @report.charts.image_post_url = {
          :controller => 'attachments',
          :action => :index,
          :only_path => true,
          :project_id => @project.id,
          :type => 'ChartImage'
        }

        render :json => @report
      end

      format.csv do
        csv = @report.to_csv(params[:table].to_i)
        send_data(csv, :filename => 'report.csv', :disposition => 'attachment')
      end

      format.pdf do
        @report.update!(@project, @current_user)
        send_data(@report.to_pdf, :filename => 'report.pdf',
                  :disposition => 'attachment')
      end

      format.xls do
        @report.update!(@project, @current_user)
        send_data(@report.to_spreadsheet, :type => 'application/excel',
                  :filename => 'report.xls', :disposition => 'attachment')
      end

    end
  end

end
