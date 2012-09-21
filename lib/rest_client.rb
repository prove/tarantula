require 'rest_client'
login_xml=File.open('login.xml').read

# login
response = RestClient.post "http://127.0.0.1:3000/api?login",login_xml,{:accept => :xml, :content_type => :xml}
puts response
