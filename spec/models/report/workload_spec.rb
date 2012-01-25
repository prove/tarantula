require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../shared/cacheable_report_spec.rb')

describe Report::Workload do
  def get_instance(opts={})
    if opts[:static]
      return Report::Workload.new(1)
    end                                    
    
    p = Project.make
    Report::Workload.new(p.id)
  end
  
  it_should_behave_like "cacheable report"
end
