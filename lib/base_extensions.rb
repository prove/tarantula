=begin rdoc

Extensions to ruby base classes.

=end


class Integer
  def to_duration
    hours = self / 3600
    minutes = (self - hours*3600)/60
    seconds = self - (hours*3600) - (minutes*60)
    hours = hours.to_s.rjust(2,'0') if hours < 10
    return "#{hours}:#{minutes.to_s.rjust(2,'0')}:#{seconds.to_s.rjust(2,'0')}"
  end
  
  def in_percentage_to(divisor)
    return 0 if divisor == 0
    return ((self.to_f / divisor)*100).round
  end
  
  # Factorize using trial division method
  def factorize
    newnum = self
    f_arr = []
    checker = 2
    while (checker*checker <= newnum)
      if newnum % checker == 0
        f_arr << checker
        newnum = newnum / checker
      else
        checker += 1
      end
    end
    f_arr << newnum if newnum != 1
    f_arr
  end
end

class Hash
  def ordered
    oh = ActiveSupport::OrderedHash.new
    self.keys.sort{|a,b| a.to_s.downcase <=> b.to_s.downcase}.each do |k|
      oh[k] = self[k]
    end
    oh
  end
end

class String
  # returns id parts of a string, as in requirement id
  # e.g. R001 => ['R',   1]
  #      1    => ['',    1]
  #      FP11 => ['FP', 11]
  def id_parts
    return ["", 0] if self.empty?
    return ["", self.to_i] if self.to_i != 0
    return [$1, $2.to_i] if self =~ /^([a-zA-Z]*)([0-9]*)/
    [self, 0]
  end
end

class Array
  
  # return {object1 => frequency1, object2 => frequency2} kind of hash
  def frequencies
    inject(Hash.new(0)) { |h,v| h[v] += 1; h }
  end
  
  # return objects in {freq1 => [objects], freq2 => [objects]} kind of hash
  def by_frequency
    h = {}
    self.frequencies.each do |obj, freq|
      h[freq] ||= []
      h[freq] << obj
    end
    h
  end
end