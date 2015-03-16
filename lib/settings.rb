require 'settingslogic'

class Settings < Settingslogic
  CONFIGURATION = 'conf.yml'

  source "#{File.dirname(__FILE__)}/#{CONFIGURATION}"

end
