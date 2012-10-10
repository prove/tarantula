class CsvExportsController < ApplicationController
  layout false
  
  before_filter do |c|
    c.require_permission(['TEST_DESIGNER'])
  end
  
  def new
  end
  
  def create
    test_area = @current_user.test_area(@project)
    klass = params[:export_type].camelcase.constantize
    if @test_area
      records = @test_area.send(klass.to_s.downcase.pluralize.to_sym).send(:active)
    else
      records = klass.active.where(:project_id => @project.id)
    end
    
    csv = klass.to_csv(';', "\r\n", :recurse => params[:recursion].to_i,
          :export_without_ids => !params[:export_without_ids].blank?) { records }
    
    send_data csv, :filename => "#{params[:export_type]}_export.csv",
                   :disposition => 'attachment'
  end
end
