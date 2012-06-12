=begin rdoc

=AttachmentSet

Following applies to models which include AttachingExtensions:

- Each (version of) model has zero or more AttachmentSets, which have a number
  of attachments. 
- The latest of the attachment sets is the current one.
- Each attach/unattach operation creates a new AttachmentSet
  
=end
class AttachmentSet < ActiveRecord::Base
  belongs_to :host, :polymorphic => true
  has_and_belongs_to_many :attachments
end
