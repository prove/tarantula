
module Import

=begin rdoc

Base class for imports.

=end  
class Base
  class ImportNotifier < ActionMailer::Base
    
    def import_notice(log, subject_text, email_addr)
      @email =  email_addr
      @subject = subject_text
      @from    = "noreply@testia.fi"
      @content = Sanitizer.instance.strip_tags(log)
      mail(:to => @email, :subject => @subject)
    end
    
  end
end

end
