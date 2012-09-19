=begin rdoc

Export cases, requirements, test sets, or executions of a project to CSV.

=end
class CsvExport
  def initialize(project, test_area, klass, recurse)
    @project =  project
    @test_area = test_area
    @klass = klass
    @recurse = recurse
  end

  def to_csv(col_sep=';', row_sep="\r\n", opts={})
    if @test_area
      objects = @test_area.send(@klass.to_s.downcase.pluralize.to_sym).send(:active)
    else
      objects = @klass.active.where(:project_id => @project.id)
    end
    csv = @klass.csv_header(col_sep, row_sep)
    csv += objects.map{|o| o.to_csv(col_sep, row_sep, 
                                    {:recurse => @recurse})}.join
    csv
  end
end
