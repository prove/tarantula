module Report

=begin rdoc

Report: A list of case executions.

=end
class CaseExecutionList < Report::Base
  SORT_BY = ['test_objects.date', #default
             'test_objects.name',
             'executions.name',
             'cases.title',
             'executed_at',
             'duration',
             'executed_by',
             'result',
             'test_objects.date', #comments
             'test_objects.date', #defects
             'test_objects.date'  #tags
             ]
  
  def initialize(project_id, 
                 test_object_ids, 
                 execution_ids,
                 tags=false,
                 test_area_id=nil,
                 sort_by=nil,
                 sort_dir=nil)
    super()
    @name = "Case Execution List"
    
    @options = { :project_id      => project_id,
                 :test_object_ids => test_object_ids,
                 :execution_ids   => execution_ids,
                 :tags            => tags,
                 :test_area_id    => test_area_id,
                 :sort_by         => sort_by.to_i,
                 :sort_dir        => sort_dir || 'desc' }
    
  end

  protected

  def do_query
    if @options[:test_object_ids]
      tos = [TestObject.find(@options[:test_object_ids])].flatten
      eids = tos.map(&:execution_ids).flatten.uniq
      sel_name = 'Test Objects'
      sel_val = tos.map(&:name).join(', ')
    else
      eids = @options[:execution_ids]
      sel_name = 'Executions'
      sel_val = [Execution.find(@options[:execution_ids])].\
        flatten.map(&:name).join(', ')
    end

    if ta = TestArea.find_by_id(@options[:test_area_id])
      eids = eids & ta.execution_ids
    end

    conds_str = "cases.project_id=:project_id AND executions.deleted=0 " +
                "and executions.id in (:eids)"

    conds_h = {:project_id => @options[:project_id],
               :eids => eids}

    columns = ActiveSupport::OrderedHash.new
    columns[:test_object] = 'Test Object'
    columns[:exec_name] = 'Execution Name'
    columns[:case_title] = 'Test Case Name'
    columns[:execution_time] = 'Execution Date'
    columns[:duration] = 'Duration (min)'
    columns[:executed_by] = 'Executed by'
    columns[:result] = 'Result [Priority]'
    columns[:comments] = 'Comments'
    columns[:defects] = 'Defects'
    columns[:tags] = 'Tags'

    ce_data = CaseExecution.find(
      :all,
      :joins => [:test_case, {:execution => :test_object}],
      :include => :test_case,
      :order   => SORT_BY[@options[:sort_by]] + " #{@options[:sort_dir]}",
      :select => "executions.name as exec_name, cases.title as case_title, "+
                 "case_executions.result, case_executions.id, "+
                 "test_objects.name as to_name, case_executions.executed_at, "+
                 "case_executions.executed_by, case_executions.duration, "+
                 "case_executions.case_id",
      :conditions => [conds_str, conds_h])

    ce_id_str = ce_data.map{|d| d.id}.join(',')
    ce_id_str = 'NULL' if ce_id_str.blank?

    com_data = ActiveRecord::Base.connection.select_all(
      "SELECT comment, case_execution_id as id FROM step_executions "+
      "WHERE step_executions.case_execution_id IN "+
      "(#{ce_id_str}) AND comment RLIKE '[:alnum:]+'"
    )

    comments = {}
    com_data.each do |row|
      comments[row['id'].to_i] ||= ''
      comments[row['id'].to_i] += row['comment']+' '
    end
    
    h1 @name
    show_params(['Project', Project.find_by_id(@options[:project_id])],
                ['Test Area', TestArea.find_by_id(@options[:test_area_id])],
                [sel_name,    sel_val])
    text_options(:size => 10)
    
    if @options[:tags]
      categorize_by_tags(ce_data, comments, columns)
    else
      data = create_data(ce_data, comments)            
      t(columns, data, :column_widths => column_widths)
    end
  end

  private
  
  def column_widths
    {0 => 80, 1 => 80, 2 => 160, 3 => 80, 4 => 60, 
     5 => 80, 6 => 80, 7 => 50, 8 => 50, 9 => 50}
  end
  
  def create_data(ce_data, comments)
    data = []
    ce_data.each do |ce|
      title = ce.test_case.title
      title += " (#{ce.failed_steps_info})" if ce.result == Failed
      e_at = ce.executed_at
      data << {
        :test_object => ce.execution.test_object.name,
        :exec_name => ce.execution.name,
        :case_title => title,
        :execution_time => e_at ? e_at.strftime('%Y-%m-%d %H:%M') : nil,
        :executed_by => ce.executed_by,
        :duration => "%.2f" % (ce.duration.to_f / 60),
        :result => "#{ce.result.ui} [#{ce.test_case.priority_name[0..0].capitalize}]",
        :comments => comments[ce.id],
        :defects => ce.bugs_to_s,
        :tags => ce.test_case.tags_to_s.gsub(',', ', ')
      }
    end
    
    if @options[:sort_by] >= 8 # sort by comments, defects, tags
      if @options[:sort_by] == 8
        field = :comments
      elsif @options[:sort_by] == 9
        field = :defects
      else
        field = :tags # 10
      end
      data.sort! do |a,b| 
        if @options[:sort_dir] == 'asc'
          a[field].to_s <=> b[field].to_s
        else
          b[field].to_s <=> a[field].to_s
        end
      end
    end
    data
  end
  
  def categorize_by_tags(ce_data, comments, columns)
    tags_map = {'Untagged' => []}
    ce_data.each do |ce|
      tags = Case.find(ce[:case_id]).tags
      tags.each do |tag|
        tags_map[tag.name] ||= []
        tags_map[tag.name] << ce[:id]
      end
      tags_map['Untagged'] << ce[:id] if tags.empty?
    end
    
    tags_map.ordered.each do |tag,ces|
      part = ce_data.select{|ce| ces.include?(ce[:id])}
      data = create_data(part, comments)
      h2 tag
      t(columns, data, :column_widths => column_widths)
    end
  end

end

end # module Report
