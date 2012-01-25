=begin rdoc

Reflects a single dashboard item.

=end
class DashboardItem
  cattr_accessor :all
  def self.find(id); (self.all || []).detect{|i| i.id == id}; end
    
  attr_reader :id

  # args_proc takes user and project as arguments and returns array of args
  # for the klass.new (or meth) method
  def initialize(id, name, klass, img, args_proc, meth=:new)
    @id, @name, @klass, @img, @args_proc, @meth = \
      id, name, klass, img, args_proc, meth
    DashboardItem.all ||= []
    DashboardItem.all << self
  end
    
  def to_report(user, project)
    @klass.constantize.send(@meth, *@args_proc.call(user, project))
  end
end

