module CsvExchange
  
  module Model
    
    def define_csv(&block)
      @csv_setup = Hash.new
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
    
    def update_from_csv(csv, project_id, user_id, logger, 
                        col_sep=';', row_sep="\r\n")
      
      lines = csv.split(row_sep)
      
      data = CSV.parse(lines.delete_at(0), :col_sep => col_sep, 
                       :row_sep => row_sep).flatten

      id_attr = csv_setup[:identifier][:name]
      id_index = csv_setup[:identifier][:index]
      
      if data[id_index] == 'new'
        logger.create_msg "Creating a new #{self}.."
        record = self.new
        record.project_id = project_id if record.respond_to?(:project_id)
        record.created_by = user_id if record.respond_to?(:created_by)
        record.updated_by = user_id if record.respond_to?(:updated_by)
      else
        record = self.find(:first, :conditions => {id_attr => data[id_index]})
        raise "Could not find #{self} with #{id_attr} #{data[id_index]}" unless record
        logger.update_msg "Update #{self} #{id_attr} #{data[id_index]}.."
      end
      
      old_children = record.send(csv_setup[:children].first) unless csv_setup[:children].empty?

      record.set_csv_attributes(data, project_id, logger)
      
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
        if data[child_class.csv_setup[:identifier][:index]] == 'new'
          logger.create_msg "Creating a new #{child_class}.."
          child_record = child_class.new
          child_record.set_csv_attributes(data, project_id, logger)
          child_record.project_id = project_id if child_record.respond_to?(:project_id)
          child_record.created_by = user_id if child_record.respond_to?(:created_by)
          child_record.updated_by = user_id if child_record.respond_to?(:updated_by)
          child_record.save!
          chunk.sub!(/new/, child_record.id.to_s)
        else
          child_record = child_class.find(:first, :conditions => {child_class.csv_setup[:identifier][:name] => data[child_class.csv_setup[:identifier][:index]]})
          raise "#{child_class} #{csv_setup[:identifier][:name]} #{data[csv_setup[:identifier][:index]]} not found" unless child_record
        end
        children << child_record
      end
      
      if old_children.sort != children.sort
        logger.update_msg("Updating #{csv_setup[:children].first} for #{self} #{csv_setup[:identifier][:name]} #{record.send(csv_setup[:identifier][:name])}")
        if child_class.attribute_names.include?('version')
          record.save! unless saved
          children.each_with_index do |ch,i|
            ch.position = i+1 if ch.respond_to?(:position)
            record.send(csv_setup[:children].first) << ch
          end
        else
          record.send("#{csv_setup[:children].first}=", children)
        end
      end

      chunks.each do |chunk|
        child_class.update_from_csv(chunk, project_id, user_id, logger, 
                                    col_sep, row_sep)
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
              if cell[:opts][:identifier] and opts[:export_without_ids]
                row << 'new'
              else
                row << send(cell[:name])
              end
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

      def set_csv_attributes(data, project_id, logger)
        self.class.csv_setup[:cells].each_with_index do |cell, i|
          case cell[:type]

          when :attribute
            next if cell[:opts][:identifier]
            att = data[i]
            att = att.send(cell[:opts][:map]) if cell[:opts][:map]
            send("#{cell[:name]}=", att)
            
            # TODO: allow creation of new association models, e.g. tags
          when :association
            assoc_model = cell[:name].to_s.classify.constantize
            new_assoc_strs = (data[i] || '').split(',').map(&:strip)
            new_assocs = []
            new_assoc_strs.each do |str|
              conds = {cell[:opts][:map] => str, :project_id => project_id}
              conds.merge!(:taggable_type => self.class.to_s) if assoc_model == Tag
              new_assoc = assoc_model.find(:first, :conditions => conds)
              raise "No #{assoc_model} #{str} found." unless new_assoc
              new_assocs << new_assoc
            end
            if [send(cell[:name])].flatten != new_assocs
              logger.update_msg("Updating #{cell[:title]} for #{self.class} #{self.class.csv_setup[:identifier][:name]} #{data[self.class.csv_setup[:identifier][:index]]}.. #{[send(cell[:name])].flatten.map{|rec| rec.send(cell[:opts][:map])}.map(&:to_s).join(', ')} => #{data[i]}")
              if cell[:name].to_s.singularize == cell[:name].to_s
                send("#{cell[:name]}=", *new_assocs)
              else
                send("#{cell[:name]}=", new_assocs)
              end
            end

          when :field
            # do nothing
          end
        end
      end
      
    end
    
  end

end
