=begin rdoc

Result type for case / step executions. A value object.

=end
class ResultType
  attr_accessor :db, :ui, :rank, :color
  cattr_accessor :all
  
  def initialize(val_hash)
    @db = val_hash[:db]
    @ui = val_hash[:ui]
    @rank = val_hash[:rank]
    @color = val_hash[:color]
    @@all ||= []
    @@all << self
  end
  
  def to_s; self.db; end
  def to_yaml; self.to_s; end
  def rep; self.ui.titleize; end # used in reporting as a key
  
  def self.method_missing(meth, *args)
    if (rt = (@@all || []).detect{|rt| [rt.db,rt.ui].include?(meth.to_s.gsub(' ','_').upcase)})
      return rt
    else
      raise "Invalid result type #{meth}!"
    end
  end
  
  # returns highest ranking result in array
  def self.result_by_rank(rt_arr)
    ResultType.all.sort{|a,b| a.rank <=> b.rank}.each do |rt|
      return rt if rt_arr.include?(rt)
    end
    raise "Invalid result array!"
  end
  
end
