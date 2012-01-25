
namespace :cache do
  desc "Prepare cache for the heaviest methods."
  task :prepare => [:environment] do
    
    # Case#last_results(test_object_ids, test_area)
    Project.all.each do |proj|
      tos = proj.test_objects.active.find(:all, :order => 'date desc', :limit => 20)
      
      tas = proj.test_areas + [nil]
      to_set = []
      
      while !tos.empty?
        to_set << tos.pop
        
        tas.each do |ta|
          if ta
            cases = ta.cases.find(:all, :conditions => ["date <= :d", {:d => to_set.last.date}])
          else
            cases = proj.cases.find(:all, :conditions => ["date <= :d", {:d => to_set.last.date}])
          end
          cases.each {|c| c.last_results(to_set.reverse.map(&:id), ta)}
        end
      end
    end
    
    # Case#history
    Case.all.each {|c| c.history}
    
  end
end