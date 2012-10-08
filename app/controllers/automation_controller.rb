require 'logger'
class AutomationController < ApplicationController
  before_filter do |c|
    c.require_permission(:any)
  end
	# cd $AT_HOME && project="${project}" execution="${execution}" steps=${steps} bundle exec rspec -e "${test}" -r ./lib/CustomTarantulaFormatter.rb -f CustomTarantulaFormatter && bundle exec rake unblock_test["${project}","${execution}","${test}"]
	def execute
		@log = File.new(Rails.public_path+'/automation_tool.log',"w+")
		execution = Execution.find(params[:execution])
		project = execution.project
		at = AutomationTool.find(project.automation_tool_id)
		case_execution = CaseExecution.find(params[:testcase_execution])
		tc = case_execution.test_case
		cmd = at.command_pattern.gsub(/\$\{steps\}/,case_execution.step_executions.length.to_s).gsub(/\$\{test\}/,tc.title).gsub(/\$\{execution\}/, execution.name).gsub(/\$\{project\}/,project.name)
		case_execution.update_attribute(:blocked, true)
		Bundler.with_clean_env do
			fork { exec "#{cmd} > #{@log.path} 2>&1" }
		end
		@log.close
		render :json => {:data => {:message => "#{at.name} started with command\n\'#{cmd}\'"}}
	end
end
