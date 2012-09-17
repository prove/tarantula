class CsvExportsController < ApplicationController
  layout false
  
  before_filter do |c|
    c.require_permission(['TEST_DESIGNER'])
  end
  
  def new
  end
  
  def create
    test_area = @current_user.test_area(@project)
    export = CsvExport.new(@project, test_area, 
                           params[:export_type].camelcase.constantize,
                           params[:recursion].to_i)
    send_data export.to_csv, 
              :filename => "#{params[:export_type]}_export.csv",
              :disposition => 'attachment'
  end
end
