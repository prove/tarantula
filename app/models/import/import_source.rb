class ImportSource < ActiveRecord::Base
  has_many :bug_trackers
  before_save :strip_whitespace

  def attributes
    ret = @attributes
    ret['encoding'] = BT_CONFIG[:jira][:encoding] || 'utf8'
    ret
  end

  private

  def strip_whitespace
    ['adapter', 'host', 'port', 'database', 'username'].each do |i|
      @attributes[i].strip! unless @attributes[i].nil?
    end
  end

end
