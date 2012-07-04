require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Report::Workload do
  def get_instance(opts={})
    if opts[:static]
      return Report::Workload.new(1)
    end                                    
    
    p = Project.make!
    Report::Workload.new(p.id)
  end
  
  it_behaves_like "cacheable report"
end
