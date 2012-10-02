class AutomationController < ApplicationController
  before_filter do |c|
    c.require_permission(:any)
  end

	def execute
		e = Execution.find(params[:execution])
		p = e.project
		at = AutomationTool.find(p.automation_tool_id)
		c = Case.find(params[:testcase])
		cmd = at.command_pattern.gsub(/\$\{testCase\}/,c.title).gsub(/\$\{execution\}/, e.name).gsub(/\$\{project\}/,p.name)
    render :json => {:data => {:cmd => cmd}}
	end
end
