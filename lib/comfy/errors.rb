module Comfy::Errors
  require File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", 'packer_error')
  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |error_file| require error_file.chomp('.rb') }
end
