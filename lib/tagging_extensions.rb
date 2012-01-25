=begin rdoc
=Tagging Extensions
This module is included to models which need tagging functionality.

=end
module TagExt
  module Base
    # ==Sets models tags to match the given tags.
    # - tag_string is a comma separated list of tag names
    # - this has to validate all tags before creating them,
    #   so no stale unused tags are created
    def tag_with(tag_string)
      transaction do
        new_tags = []
        existing_tags = []
      
        tag_string.split(',').uniq.each do |tag_name|
          tag_name.strip!
          tag = Tag.find(:first, :conditions => 
            {:name => tag_name, :project_id => self.project_id, 
             :taggable_type => self.class.to_s})
          if tag
            existing_tags << tag
          else
            tag = Tag.new(:name => tag_name, :project_id => self.project_id,
                          :taggable_type => self.class.to_s) 
            raise "Tag error: #{tag.errors.full_messages}" unless tag.valid?
            new_tags << tag
          end
        end

        (self.tags - existing_tags).each do |t|
          tagg = self.taggings.find_by_tag_id(t.id)
          tagg.destroy if tagg
        end
      
        new_tags.each do |tag|
          tag.save!
          self.tags << tag
        end
      
        existing_tags.each do |tag|
          self.tags << tag unless self.tags.include?(tag)
        end
      
        self.tags
      end
    end
    
    def tags_to_s
      self.tags.ordered.compact.map{|t| t.name}.join(',')
    end
    
    # == Check if model has all the given tags
    def has_tags?(expected)
      return (expected | self.tags).size == self.tags.size
    end
    
  end
  
  module ClassMethods
    def find_with_tags(tags_p, opts = {})
      p = opts[:project]
      raise "give a project for find_with_tags" unless p
      
      name_field = 'name'
      name_field = 'title' if self.column_names.include?('title')
      
      conds = []
      conds << opts[:conditions] unless opts[:conditions].blank?
      if tags_p == 'deleted'
        tags_p = []
        conds << "#{self.table_name}.deleted = 1" 
      elsif tags_p == 'archived'
        tags_p = []
        conds << "#{self.table_name}.archived = 1"
      else
        conds << "#{self.table_name}.deleted = 0"
        conds << "#{self.table_name}.archived = 0"
      end
      tags_p ||= []
      
      if opts[:filter]
        conds << "#{self.table_name}.`#{name_field}` LIKE '%#{opts[:filter]}%'"
      end
      
      find_opts = {:offset => (opts[:offset] || 0),
                   :limit => opts[:limit] || Testia::LOAD_LIMIT,
                   :joins => ''}
      
      if opts[:smart_tags]
        opts[:smart_tags].each do |st| 
          conds << st.conditions(self, opts[:project], opts[:test_area])
          find_opts[:joins] += (st.joins+' ') if !st.joins.blank? and !find_opts[:joins].include?(st.joins)
        end
      end
      
      unless tags_p.blank?
        find_opts[:joins] += "JOIN taggings ON taggings.taggable_type='#{self}' AND taggings.taggable_id=#{self.table_name}.id"
        tags_p.each do |t|
          conds << "EXISTS (SELECT id FROM taggings WHERE taggable_id="+
            "#{self.table_name}.id AND taggable_type='#{self.to_s}' AND "+
            "tag_id=#{t.id})"
        end
      end
      
      if opts[:test_area]
        tbl = self.reflections[:test_areas].options[:join_table]
        conds << "EXISTS (SELECT test_area_id FROM #{tbl} WHERE "+
                 "#{self.to_s.underscore}_id=#{self.table_name}.id AND "+
                 "test_area_id=#{opts[:test_area].id})"
      end
      
      find_opts[:conditions] = conds.join(' AND ')
      find_opts[:select] = "DISTINCT #{self.table_name}.*"
      
      ret = p.send(self.table_name).ordered.find(:all, find_opts)
      
      ret || []
    end
    
  end
  
end

module TaggingExtensions
  include TagExt::Base
  
  def self.included(model)
    model.extend TagExt::ClassMethods
    model.has_many :taggings, :as => :taggable
    model.has_many :tags, :through => :taggings
    model.after_destroy do |record|
      record.taggings.destroy_all
    end
  end
end
