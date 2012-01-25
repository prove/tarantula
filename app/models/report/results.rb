module Report

=begin rdoc

Report: A low-level report used to get results with select criteria.

=end
class Results < Report::Base
  
  def initialize(project_id, conditions=["",{}], exclude_duplicates=false)
    super()
        
    @name = "Test Execution Results"
    
    @options = { :project_id => project_id,
                 :conditions => [conditions[0], conditions[1].ordered],
                 :exclude_duplicates =>  exclude_duplicates }
  end
  
  # Combines result_arr of Report::Results
  # returns [columns, data, data_percentages] to be added with t()
  def self.combine(part_names, results)
    data = []
    data_perc = []
    cols = ActiveSupport::OrderedHash.new
    cols[:name] = ''
    part_names.each_with_index{|pn,i| cols["part_#{i}".to_sym] = pn}
    
    ResultType.all.map(&:rep).each_with_index do |res_type, rt_i|
      h = {:name => res_type }
      hp = {:name => res_type }
      results.each_with_index do |res, res_i|
        res.query
        data_cell = res.tables.first.data[rt_i]
        h.merge!("part_#{res_i}".to_sym => data_cell[:test_results])
        hp.merge!("part_#{res_i}".to_sym => data_cell[:perc])
      end
      data << h
      data_perc << hp
    end
    
    exec_row = {:name => "Executed Cases"}
    tc_row   = {:name => "Testing Coverage"}
    tot_row  = {:name => "Total Cases"}
    
    # Executed cases, testing coverage, and total cases
    results.each_with_index do |res, res_i|
      d = res.tables.first.data
      exec_perc = 100 - d[4][:test_results].in_percentage_to(d[5][:excl_results])
      exec_row["part_#{res_i}".to_sym] = "#{exec_perc}%"
      tc_perc = (d[0][:test_results] + d[1][:test_results]).in_percentage_to(d[5][:excl_results])
      tc_row["part_#{res_i}".to_sym]   = "#{tc_perc}%"
      tot_row["part_#{res_i}".to_sym]  = d[5][:test_results]
    end
    
    data_perc << exec_row << tc_row << tot_row
    
    [cols, data, data_perc]
  end
  
  protected
  
  def do_query
    columns = ActiveSupport::OrderedHash.new
    columns[:name] = '' 
    columns[:test_results] = 'Test Results' 
    columns[:perc] = '%' 
    columns[:all_cases] = 'All Cases'
    
    conds_str = @options[:conditions][0]
    conds_str = ' AND '+conds_str unless conds_str.blank?
    conds_hash = @options[:conditions][1]

    base_conds = ["executions.project_id=:project_id" + conds_str,
                  {:project_id => @options[:project_id]}.merge(conds_hash)]
    
    if @options[:exclude_duplicates]
      valids = {}
      ces = CaseExecution.find(:all, :joins => [:execution, :test_case],
                               :conditions => base_conds)
      ces.each do |ce|
        cid = ce.case_id
        if valids[cid].nil?
          valids[cid] = ce
        else
          next if ce.executed_at.nil?
          valids[cid] = ce if valids[cid].executed_at.nil? or ce.executed_at > valids[cid].executed_at
        end
      end

      base_conds[0] = 'case_executions.id in (:ce_ids) and ' + base_conds[0]
      base_conds[1].merge!({:ce_ids => valids.values.map(&:id)})
    end
    
    ces = CaseExecution.find(:all, :joins => [:execution, :test_case],
                             :conditions => base_conds)    
    total = ces.size
    total_steps = ces.map(&:step_execution_ids).flatten.size
    project_total = Case.count(
      :conditions => {:project_id => @options[:project_id],
                      :deleted => false})
    data = []
    res_total = 0 
    
    ResultType.all.each do |res_type|
      count_conds = ["case_executions.result=:result AND " + base_conds[0],
                     base_conds[1].merge({:result => res_type.db})]

      res = CaseExecution.count(:joins => [:execution, :test_case],
                                :conditions => count_conds) || 0
      
      data << {:name => res_type.rep, 
               :test_results => res, 
               :perc => "#{res.in_percentage_to(total)}%",
               :all_cases => "#{res.in_percentage_to(project_total)}%" }
      res_total += res
    end
    
    data << {:name => 'Total',
             :test_results => "#{total} (#{total_steps})",
             :excl_results => total,
             :perc => "#{res_total.in_percentage_to(total)}%",
             :all_cases => "#{res_total.in_percentage_to(project_total)}%" }

    data << {:name => 'project total',
             :cases => project_total}
    
    h1 @name
    t(columns, data)
  end
  
end

end # module Report
