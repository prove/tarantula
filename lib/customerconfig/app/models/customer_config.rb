=begin rdoc

Customer specific key => value configs.

=end
class CustomerConfig < ActiveRecord::Base

  def value=(val)
    self['value'] = val.to_yaml
  end

  def value
    return nil if self['value'].nil?
    YAML.load(self['value'])
  end

  private

  def self.set_config(cc_name, val, required=false)
    conf = CustomerConfig.find(:first, :conditions => {:name => cc_name})
    if conf
      conf.update_attributes!(:value => val, :required => required)
    else
      CustomerConfig.create!(:name => cc_name, :value => val, :required => required)
    end
  end

  def self.method_missing(meth, *args)
    begin
      if meth.to_s =~ /^(.*)=$/
        set_config($1, *args)
      elsif conf = CustomerConfig.find(:first,
                                       :conditions => {:name => meth.to_s})
        return conf.value
      end
    rescue
      Rails.logger.warn "Couldn't access configuration at "+
        "#{__FILE__}:#{__LINE__}. Returning nil."
      return nil
    end
  end
end
