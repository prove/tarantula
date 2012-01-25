=begin rdoc

=ChangeHistory
This module includes functionality for getting the change history 
for versioned models.

=end
module ChangeHistory
  
  def self.included(model)
    model.before_create :set_created_change_comment
  end
  
  def set_created_change_comment
    self.change_comment = 'created' if self.change_comment.blank?
  end
  
  def change_history
    results = []

    self.versions.reverse.each do |ver|
      a_user = User.find_by_id(ver.updated_by)
      users_login = (a_user.nil? ? 'unknown' : a_user.login)
      
      results << {:user => users_login, 
                  :time => ver.updated_at,
                  :comment => ver.change_comment}
    end
    results
  end
  
end