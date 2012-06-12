Dir.glob("#{Rails.root}/lib/attsets/app/**/*.rb").each do |path|
  require path
end
require "#{Rails.root}/lib/attsets/lib/attaching_extensions"

