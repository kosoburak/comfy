require 'settingslogic'

class Settings
  CONFIGURATION = 'confy.yml'

  source "#{File.dirname(__FILE__)}/#{CONFIGURATION}"

end
