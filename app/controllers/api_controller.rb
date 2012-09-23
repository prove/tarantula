class ApiController < ApplicationController
	skip_filter :set_current_user_and_project
	before_filter :login_once
	respond_to :xml

	def test
		respond_with @users=User.all
	end

	private
	def login_once
		authenticate_or_request_with_http_basic do |username, password|
      if can_do_stuff?(username,password)
				set_current_user_and_project
			end
		end
	end
end
