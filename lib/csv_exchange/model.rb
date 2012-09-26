module CsvExchange
  
  module Model
    
    def define_csv(&block)
      @csv_setup = Hash.new
      CsvExchange::Info.add_class(self)
      CsvExchange::Setup.new(@csv_setup).instance_eval(&block)
      include InstanceMethods
    end

    def csv_setup
      @csv_setup
    end

    def csv_header(col_sep=';', row_sep="\r\n", opts={})
      CSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
        row = []
        row = [''] * opts[:indent] if opts[:indent]
        @csv_setup[:cells].each do |cell|
          row << cell[:title]
        end
        csv << row
      end
    end

    def to_csv(col_sep=';', row_sep="\r\n", opts={})
      if block_given?
        records = yield
      else
        records = self.all
      end
      csv = csv_header(col_sep, row_sep, opts)
      csv += records.map{|record| record.to_csv(col_sep, row_sep, opts)}.join
    end
    
    def update_from_csv(csv, logger, col_sep=';', row_sep="\r\n")
      
      lines = csv.split(row_sep)
      
      data = CSV.parse(lines.delete_at(0), :col_sep => col_sep, 
                       :row_sep => row_sep).flatten

      id_attr = csv_setup[:identifier][:name]
      id_index = csv_setup[:identifier][:index]
      
      record = self.find(:first, :conditions => {id_attr => data[id_index]})
      raise "Could not find #{self} with #{id_attr} #{data[id_index]}" unless record
      logger.update_msg "Update #{self} #{id_attr} #{data[id_index]}.."
      new_attributes = {}
      
      old_children = record.send(csv_setup[:children].first) unless csv_setup[:children].empty?

      csv_setup[:cells].each_with_index do |cell, i|
        case cell[:type]

        when :attribute
          next if cell[:opts][:identifier]
          attribute = data[i]
          attribute = attribute.send(cell[:opts][:map]) if cell[:opts][:map]
          new_attributes[cell[:name]] = attribute

        # TODO: allow creation of new association models, e.g. tags
        when :association
          assoc_model = cell[:name].to_s.classify.constantize
          new_assoc_strs = data[i].split(',').map(&:strip)
          new_assocs = []
          new_assoc_strs.each do |str|
            new_assoc = assoc_model.find(:first, 
                                  :conditions => {cell[:opts][:map] => str})
            raise "No #{assoc_model} #{str} found." unless new_assoc
            new_assocs << new_assoc
          end
          if [record.send(cell[:name])].flatten != new_assocs
            logger.update_msg("Updating #{cell[:title]} for #{self} #{id_attr} #{data[id_index]}.. #{[record.send(cell[:name])].flatten.map{|rec| rec.send(cell[:opts][:map])}.map(&:to_s).join(', ')} => #{data[i]}")
            if cell[:name].to_s.singularize == cell[:name].to_s
              record.send("#{cell[:name]}=", *new_assocs)
            else
              record.send("#{cell[:name]}=", new_assocs)
            end
          end

        when :field
          # do nothing
        end
      end
      record.attributes = new_attributes
      saved = false
      if !record.changes.empty?
        logger.update_msg("Updating attributes for #{self} #{id_attr} #{data[id_index]}: #{record.changes.inspect}")
        record.save!
        csv_setup[:after_update].call(record) if csv_setup[:after_update]
        saved = true
      end

      if lines.empty?
        record.send("#{csv_setup[:children].first}=", old_children) if saved and old_children 
        return
      end
      
      raise "No children defined" if csv_setup[:children].blank?
      lines.map! do |line|
        if line =~ /^""#{col_sep}/
          line = line[3..-1]
        elsif line =~ /^#{col_sep}/
          line = line[1..-1]
        else
          raise "Wrong indent"
        end
      end
      
      header = lines.delete_at(0)
      child_class = csv_setup[:children].first.to_s.classify.constantize
      raise "Wrong child header" if (header+row_sep) != child_class.csv_header(col_sep, row_sep)
      return if lines.empty? # only child header
      chunks = CsvExchange::Import.chunkify(lines, col_sep, row_sep)
      children = []
      
      chunks.each do |chunk|
        data = CSV.parse(chunk.split(row_sep).first, :col_sep => col_sep, 
                         :row_sep => row_sep).flatten
        child_record = child_class.find(:first, :conditions => {child_class.csv_setup[:identifier][:name] => data[csv_setup[:identifier][:index]]})
        raise "#{child_class} #{csv_setup[:identifier][:name]} #{data[csv_setup[:identifier][:index]]} not found" unless child_record
        children << child_record
      end
      
      if old_children.sort != children.sort
        logger.update_msg("Updating #{csv_setup[:children].first} for #{self} #{csv_setup[:identifier][:name]} #{record.send(csv_setup[:identifier][:name])}")
        record.save! unless saved
        children.each_with_index do |ch,i|
          ch.position = i+1 if ch.respond_to?(:position)
          record.send(csv_setup[:children].first) << ch
        end
      end

      chunks.each do |chunk|
        child_class.update_from_csv(chunk, logger, col_sep, row_sep)
      end
    end

    module InstanceMethods
      def to_csv(col_sep=';', row_sep="\r\n", opts={})
        
        ret = CSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
          row = []
          row = [''] * opts[:indent] if opts[:indent]
          
          self.class.csv_setup[:cells].each do |cell|
            case cell[:type]
            when :attribute
              row << send(cell[:name])
            when :association
              records = [send(cell[:name])].flatten
              data = records.map{|rec| rec.send(cell[:opts][:map])}
              data = data.map(&:to_s).join(', ')
              row << data
            when :field
              row << send(cell[:name])
            end
          end
          csv << row
        end
        
        if opts[:recurse] and opts[:recurse] > 0 and !self.class.csv_setup[:children].empty?
          new_opts = opts.dup
          new_opts[:recurse] -= 1
          new_opts[:indent] ||= 0
          new_opts[:indent] += 1
          self.class.csv_setup[:children].each do |ch|
            ch_records = send(ch)
            next if ch_records.empty?
            ch_class = ch.to_s.classify.constantize
            ret += ch_class.csv_header(col_sep, row_sep, new_opts)
            ret += ch_records.map{|c| c.to_csv(col_sep, row_sep, new_opts)}.join
          end
        end
        ret
      end
    end
    
  end

end
