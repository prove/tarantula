=begin rdoc

Tagging observer.

=end
class TaggingObserver < ActiveRecord::Observer
  def after_destroy(tagging)
    # If this is last tagging for given tag, delete "empty" tag also.
    tag = tagging.tag
    if tag.taggings.size == 0
      tag.destroy
    end
  end
end
