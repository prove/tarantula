class CsvImportsController < ApplicationController
  layout false
  
  def new
  end

  def create
    import = CsvImport.new(params[:file], @project, @current_user,
                           params[:simulate])
    @log = import.log
    render :template => '/import/log'
  end
end
