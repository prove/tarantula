class ApiError < StandardError
	def initialize(msg, request_details)
		super msg.upcase + "\tREQUETS DETAILS:\t#{request_details}\n"
	end
end
