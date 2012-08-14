class BackupsController < ApplicationController
  layout false
  
  before_filter do |c|
    c.require_permission(['ADMIN'])
  end

  def new
  end

  def create
    backup = Backup.new
    backup.process
    send_file Backup::BACKUP_ZIP, :type => 'application/zip'
  end
  
end
