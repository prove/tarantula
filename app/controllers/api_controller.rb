class ApiController < ApplicationController
	respond_to :xml, :json

	def login
		puts params
	end
end
