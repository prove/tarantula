class AttachmentsController < AttachmentsControllerBase
  before_filter :only => [:create, :destroy] do |c|
    c.require_permission(['TEST_DESIGNER','MANAGER'])
  end
  before_filter :only => [:index, :show] do |c|
    c.require_permission(:any)
  end

  private

  def get_file_data_file_names_and_attributes(klass)
    if klass == ChartImage
      file_data = request.body # StringIO
      file_names = []
      atts = {:data => params[:key]}
    else
      file_data = params[:file_data]
      file_names = get_upload_filenames
      atts = {}
    end
    [file_data, file_names, atts]
  end

  def get_upload_filenames
    request.env['rack.request.form_hash']['file_data'].map{|h| h[:filename]}
  end

  def get_host
    if params[:case_id]
      @host = Case.find(params[:case_id])
    elsif params[:case_execution_id]
      case_exec = CaseExecution.find(params[:case_execution_id])
      @host = Case.find(case_exec.case_id)
      @host.revert_to(case_exec.case_version)
      # TODO: prevent (un)attaching
    elsif params[:requirement_id]
      @host = Requirement.find(params[:requirement_id])
    elsif params[:test_object_id]
      @host = TestObject.find(params[:test_object_id])
    elsif params[:project_id]
      @host = Project.find(params[:project_id])
    end
  end

end
