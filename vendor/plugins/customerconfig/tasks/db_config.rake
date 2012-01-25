namespace :db do

  desc "Ask and set application configuration variables & configure servers"
  task :config => ['db:config:app', 'db:config:servers', 'db:config:generate']

  namespace :config do

    module CC
      RECONFIG_CUSTOMER = true

      def self.ask_reconfig
        reconf = ask("Do you want to reconfigure all existing settings? (y/N)")
        const_set("RECONFIG_CUSTOMER", (reconf.to_s.downcase == 'y'))
      end

      def self.ask(message, old_val=nil, default=nil)
        return old_val if !old_val.nil? and !RECONFIG_CUSTOMER

        if !old_val.nil?
          puts "#{message} [#{old_val}]"
        elsif !default.nil?
          puts "#{message} {#{default}}"
        else
          puts message
        end

        val = STDIN.gets.strip

        return (old_val || default) if val.blank?

        if val == 'false'
          val = false
        elsif val == 'true'
          val = true
        end

        val
      end

      def self.ask_hash(keys, messages, old_val=nil, defaults={})
        return old_val if !old_val.nil? and !RECONFIG_CUSTOMER

        new_hash = defaults.dup
        new_hash.merge!(old_val) if old_val

        keys.each_with_index do |key,i|
          puts new_hash[key] ? "#{messages[i]} [#{new_hash[key]}]" : messages[i]
          val = STDIN.gets.strip
          new_hash[key] = val unless val.blank?
        end
        new_hash
      end

      def self.ask_host_info
        return if ![CustomerConfig.protocol, CustomerConfig.host, CustomerConfig.port].include?(nil) and !RECONFIG_CUSTOMER

        old_val = CustomerConfig.host ? "#{CustomerConfig.protocol}://#{CustomerConfig.host}:#{CustomerConfig.port}" : nil
        input = ask("- Protocol, host, and port (e.g. 'http://yourdomain.com')", old_val)
        protocol, host, port = input.split(':')
        CustomerConfig.protocol = protocol
        CustomerConfig.host = host.split('//')[1]
        CustomerConfig.port = port
      end

      def self.ask_smtp_info
        return if !CustomerConfig.smtp.nil? and !RECONFIG_CUSTOMER

        CustomerConfig.smtp = ask_hash(
          [:address, :port, :domain],
          ["- Address (e.g. 'smtp.yourmailserver.com')",
           "- Port (e.g. '25')",
           "- Domain (e.g. 'yourdomain.com')"],
          CustomerConfig.smtp)
      end

    end

    desc "Ask and set a single configuration variable in DB."
    task :set => [:environment] do
      key = CC.ask("Give variable name (#{CustomerConfig.all.map(&:name).join(', ')})")
      val = CustomerConfig.send(key)

      if val.is_a?(Hash)
        new_val = {}
        val.each do |k,v|
          new_val[k] = CC.ask("#{key} - #{k}", v)
        end
        CustomerConfig.send("#{key}=", new_val)
      else
        CustomerConfig.send("#{key}=", CC.ask("Value", CustomerConfig.send(key)))
      end
    end

    desc "Configure web and application servers."
    task :servers => [:environment] do
      puts "\nSERVERS"

      CustomerConfig.web_port = CC.ask("Web server port", CustomerConfig.web_port, 3000).to_i
      CustomerConfig.use_ssl = ([true, 'y', 'Y'].include?(CC.ask("Use SSL (y/n)", CustomerConfig.use_ssl, false)))

      if CustomerConfig.use_ssl
        CustomerConfig.redirect_port = CC.ask("Redirect http to https from "+
                                              "port (give zero or empty, if "+
                                              "you don't want to redirect)",
                                              CustomerConfig.redirect_port).to_i
      end

      CustomerConfig.app_servers = CC.ask("Number of application servers", CustomerConfig.app_servers, 3).to_i
      CustomerConfig.app_port = CC.ask("First application server port", CustomerConfig.app_port, CustomerConfig.web_port+1).to_i
    end

    desc "Generate configs from templates (nginx / monit)."
    task :generate => :environment do
      rails_path = Pathname.new(RAILS_ROOT)
      monit_path = rails_path.join('../conf/monit.d')
      nginx_path = rails_path.join('../conf/nginx.d')

      # these instance variables are used by the ERB config templates
      @app_name = RAILS_ROOT.split('/')[-2,2].join('-')
      @monitrc_path     = monit_path.join("#{@app_name}").to_s
      FileUtils.mkdir_p(monit_path.to_s)
      @nginx_conf_path  = nginx_path.join("#{@app_name}").to_s
      FileUtils.mkdir_p(nginx_path.to_s)
      @web_port    = CustomerConfig.web_port
      @ssl         = CustomerConfig.use_ssl
      @redirect_port = CustomerConfig.redirect_port
      @app_servers = CustomerConfig.app_servers
      @app_port    = CustomerConfig.app_port

      @tarantula_user = CC.ask("Which user will be running Tarantula processes?", "testia")

      content = ERB.new(File.read(File.join(File.dirname(__FILE__), '..', 'lib', 'monitrc.erb'))).result
      File.open(@monitrc_path, 'w') {|f| f.write content}
      puts "Wrote #{@monitrc_path}"

      content = ERB.new(File.read(File.join(File.dirname(__FILE__), '..', 'lib', 'nginx.conf.erb'))).result
      File.open(@nginx_conf_path, 'w') {|f| f.write content}
      puts "Wrote #{@nginx_conf_path}"
    end

    task :soft => :environment do
      if CustomerConfig.table_exists?
        not_set = CustomerConfig.find(:all, :conditions => {:value => nil})
        unless not_set.empty?
          puts '*'*79
          puts
          puts "WARNING: Following configuration variables have not been set:"
          puts not_set.map(&:name).join(', ')
          puts "Run 'rake db:config' to set them. No restarts required."
          puts
          puts '*'*79
        end
        Rake::Task['db:config:generate'].invoke
      else
        Rake::Task['db:config'].invoke
      end
    end

  end

end
