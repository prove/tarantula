class ReportDataController < ApplicationController
  
  def show
    rdata = Report::Data.find(:last, :conditions => {:key => params[:id]})
    render :json => rdata.data
  end
  
  def create
    data = request.POST 
    data.delete(:key) # if key comes in post data, not query string
    
    Report::Data.create!(:user_id    => params[:user_id],
                         :project_id => params[:project_id],
                         :data       => data,
                         :key        => params[:key])
                         
    render :nothing => true, :status => :created
  end
  
end
