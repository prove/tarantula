module CsvExchange
  module Info
    def self.add_class(klass)
      @@classes ||= []
      @@classes << klass
    end
    def self.classes
      @@classes
    end
  end
end
