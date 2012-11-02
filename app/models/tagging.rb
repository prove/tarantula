=begin rdoc

The Tagging join model. 

=end
class Tagging < ActiveRecord::Base 
 
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  
  validate :check_taggable_types_match, :check_taggable_in_right_project
  validates_presence_of :tag_id, :taggable_id, :taggable_type
  
  private
  
  def check_taggable_types_match
    if self.taggable_type != tag.taggable_type
      self.errors.add(:taggable_type, "mismatch")
    end
  end
  
  def check_taggable_in_right_project
    if self.tag.project_id != self.taggable.project_id
      self.errors.add(:project_id, 
                      "Tag and taggable not in the same project!")
    end
  end
end
