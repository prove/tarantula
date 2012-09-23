class ApiController < ApplicationController
	skip_before_filter :set_current_user_and_project
	before_filter :login_once
	after_filter :logout_once
	respond_to :xml

	def test
		respond_with @users=User.all
	end

	private
	def login_once
		authenticate_or_request_with_http_basic do |username, password|
			if username == 'admin' && password == 'admin'
				puts username
				session[:user_id] = User.find_by_login(username)
			end
		end
	end
	def logout_once
		session[:user_id]=nil
	end
end
