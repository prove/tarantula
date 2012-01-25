
# just define the helper modules so we don't need the empty files
Dir.glob(File.join(RAILS_ROOT, 'app/controllers', '*.rb')).each do |cont|
  name = File.basename(cont).split('_controller.rb').first
  name = name.split('.rb').first
  eval "module #{name.camelize}Helper; end"
end

