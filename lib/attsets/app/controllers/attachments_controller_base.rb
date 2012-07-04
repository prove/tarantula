=begin rdoc

Base attachments controller to be inherited.

=end
class AttachmentsControllerBase < ApplicationController
  before_filter :get_host

  def index
    data = @host.attachments.map{|a| a.to_data}
    data.each do |h|
      h[:url] = "/#{@host.class.table_name}/#{@host.id}/attachments/#{h[:id]}"
    end
    render :json => data
  end

  # send the attachment's file
  def show
    attachment = @host.attachments.find(params[:id])

    # Currently we are not using X-Accel-Redirect or X-Sendfile headers
    # TODO: If current send_file implementation block app server, fix me
    #
    #if RAILS_ENV == 'production'
    #  # This assumes we are using Nginx in production
    #  response.headers['X-Accel-Redirect'] = attachment.access_path
    #  response.headers['Content-type'] = 'application/octet-stream'
    #  response.headers['Content-Disposition'] =
    #    "attachment; filename=\"#{attachment.orig_filename}\""
    #  render :nothing => true
    #else
    #  # This blocks the mongrel.. good enough in development
    send_file(attachment.access_path,
              :filename => attachment.orig_filename,
              :type => 'application/octet-stream')
    #end
  end

  def create
    att_data = []
    file_names = []
    klass = (params[:type] || 'Attachment').constantize

    file_data, file_names, atts = get_file_data_file_names_and_attributes(klass)

    file_data = [file_data] unless file_data.is_a?(Array)
    
    Attachment.transaction do
      file_data.each_with_index do |d,i|
        unless file_names.empty?
          atts.merge!({:file_data => [file_names[i], d]})
        else
          atts.merge!({:file_data => d})
        end
        
        attachment = klass.create!(atts)
        @host.attach(attachment)
        att_data << attachment.to_data
      end
    end
    # Workaround. Ext can't handle response properly if it's json.
    # More info at: http://extjs.com/forum/showthread.php?t=4970
    render :layout => false,
      :inline => "<pre class='attachment_response'>#{URI.escape(att_data.to_json)}</pre>",
      :status => 200
  end

  def destroy
    attachment = @host.attachments.find(params[:id])
    @host.unattach(attachment)
    render :nothing => true
  end

  # TODO: link action

  private

  def get_file_data_file_names_and_attributes(klass)
    raise "Please define #get_file_data_file_names_and_attributes in your AttachmentsController!"
  end

  def get_host
    raise "Please define #get_host in your AttachmentsController!"
  end

end
