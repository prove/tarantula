=begin rdoc

Include this module to models which need attachments.

Note: You should use #attach and #unattach, not #attachments << ... 
      or the like.

=end
module AttachingExtensions
  
  def self.included(host)
    host.instance_eval { define_method(:version) {0} } \
      unless host.column_names.include?('version')
    
    host.has_many :all_attachment_sets, :class_name => 'AttachmentSet',
                  :as => :host, :order => 'id DESC',
        :conditions => proc {"host_version <= #{self.version}"}

    host.has_one :attachment_set, :as => :host, :order => 'id DESC',
        :conditions => proc {"host_version <= #{self.version}"}
    
    host.delegate :attachments, :to => '(self.attachment_set or return [])'    
  end
  
  def attach(att)
    raise "Expected Attachment, not #{att.class}" unless att.is_a? Attachment
    
    # close in transaction getting the current set and creating a new
    self.class.transaction do
      lock!
      AttachmentSet.transaction do
        set = self.all_attachment_sets.find(:first, :lock => true)
        return false if set and set.attachments.include?(att)
      
        new_attachments = set ? set.attachments : []
        new_attachments += [att]
        AttachmentSet.create!(:host_id => self.id,
                              :host_type => self.class.to_s,
                              :host_version => self.version,
                              :attachments => new_attachments)
      end
      
      self.clear_association_cache
      att
    end
  end
  
  def unattach(att)    
    # close in transaction getting the current set and creating a new
    self.class.transaction do 
      lock!
      AttachmentSet.transaction do
        set = self.all_attachment_sets.find(:first, :lock => true)
        return false if !set or !set.attachments.include?(att)
      
        new_attachments = set.attachments - [att]
      
        AttachmentSet.create!(:host_id => self.id,
                              :host_type => self.class.to_s,
                              :host_version => self.version,
                              :attachments => new_attachments)
        end
    
        self.clear_association_cache
        att
      end
    end
  
  private
  
end
