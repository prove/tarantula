=begin rdoc

Import a CSV file.

=end
class CsvImport
  class SimulationDone < StandardError; end
  
  def initialize(file, project, user,
                 simulate=false, col_sep=';', row_sep="\r\n")
    @lines = file.read.split(row_sep)
    @project = project
    @user = user
    @simulate = simulate
    @col_sep = col_sep
    @row_sep = row_sep
    @log = StringIO.new
    @logger = Import::ImportLogger.new(@log)    
    process
  end
  
  def log; @log.string; end
  
  def process
    @logger.create_msg("Starting a new CSV import..")
    begin
      raise "Under construction"
      find_header
      @klass.transaction do
        update_from_csv
        if @simulate
          raise SimulationDone.new
        else
          @logger.info "Done."
        end
      end
    rescue SimulationDone => e
      @logger.info "Simulation done."
    rescue Exception => e
      @logger.error_msg e.message
    end
  end

  private
  
  def find_header
    headers = {Case.csv_header(@col_sep, @row_sep)        => Case,
               Requirement.csv_header(@col_sep, @row_sep) => Requirement,
               TestSet.csv_header(@col_sep, @row_sep)     => TestSet,
               Execution.csv_header(@col_sep, @row_sep)   => Execution}
    
    while(line = @lines.delete_at(0))
      next if line.empty?
      if @klass = headers[line+@row_sep]
        @logger.info "Found #{@klass} header."
        break
      else
        raise "Unknown CSV header: \"#{line}\""
      end
    end
  end

  def update_from_csv
    chunks = []
    chunk = @lines.delete_at(0)
    while(line = @lines.delete_at(0))
      if line =~ /^"";.*/ or line[0,1] == ';'
        chunk += @row_sep+line
      else
        chunks << chunk
        chunk = line
      end
    end
    chunks << chunk
    chunks.each do |c|
      @klass.update_from_csv(c, @project, @user, @col_sep, @row_sep)
    end
  end

end
