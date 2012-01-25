
module Import

=begin rdoc

Base class for imports.

=end  
class Base
  class ImportNotifier < ActionMailer::Base
    
    def import_notice(log, subject_text, email_addr)
      recipients email_addr
      subject subject_text
      from "noreply@testia.fi"
      body :content => Sanitizer.instance.strip_tags(log)
    end
    
  end
end

end