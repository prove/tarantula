=begin rdoc

Export cases or requirements of a project to CSV.

=end
class CSVExport
  def initialize(project, test_area, klass, recurse)
    @project =  project
    @test_area = test_area
    @klass = klass
    @recurse = recurse
  end

  def to_csv(delimiter=';', line_feed="\r\n", opts={})
    if @test_area
      objects = @test_area.send(@klass.to_s.pluralize.to_sym).send(:active)
    else
      objects = @klass.active.where(:project_id => @project.id)
    end
    csv = @klass.csv_header(delimiter, line_feed)
    csv += objects.map{|o| o.to_csv(delimiter, line_feed, 
                                    {:recurse => @recurse})}.join
    csv
  end
end
