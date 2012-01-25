class CustomerConfigsController < ApplicationController

  def index
    @customer_configs = CustomerConfig.all
    render :layout => false
  end

  def show
  end
  
  def new
    @customer_config = CustomerConfig.new
    render :layout => false
  end
  
   def edit
     @customer_config = CustomerConfig.find(params[:id])
     render :layout => false
  end
   
   def create
     @customer_config = CustomerConfig.new
     @customer_config[:name] = params[:customer_config][:name]
     @customer_config[:value] = params[:customer_config][:value]

     @customer_config.save!
     
     redirect_to "/customer_configs"
   end
 
   def update
     @customer_config = CustomerConfig.find(params[:id])
     @customer_config[:name] = params[:customer_config][:name]
     @customer_config[:value] = params[:customer_config][:value]
     
     @customer_config.save!
     
     redirect_to "/customer_configs"
    
   end
  
   def destroy
     @customer_config = CustomerConfig.find(params[:id])
     @customer_config.destroy
     
     redirect_to "/customer_configs"
   end
   
   def restart
     system "killall mongrel_rails ruby"
     redirect_to "/"
   end
   
end
