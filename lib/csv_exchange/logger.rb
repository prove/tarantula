
module CsvExchange
  class Logger < ::Logger
    CreateColor = "\#77ff77"
    UpdateColor = "\#ffff88"
    ErrorColor  = "\#ff7777"
  
    def initialize(*args)
      super
      self.level = Logger::INFO
      @markup = true
    end
    
    def markup=(m)
      @markup = m
    end
    
    def format_message(severity, timestamp, progname, msg)
      out = "#{timestamp} [#{severity}] #{msg}"
      out = ("<p>"+out+"</p>") if @markup
      out += "\n"
      out
    end
    
    def colorize(msg, color)
      return msg unless @markup
      "<span style=\"background-color:#{color}\">#{msg}</span>"
    end
    
    # log entity creation
    def create_msg(msg)
      self.info colorize(msg, CreateColor)
    end
    
    # log entity update
    def update_msg(msg)
      self.info colorize(msg, UpdateColor)
    end
  
    def error_msg(msg)
      self.fatal colorize(msg, ErrorColor)
    end
    
  end
  
end
