require 'settingslogic'

class Settings < Settingslogic
  CONFIGURATION = 'conf.yml'

  source "#{File.dirname(__FILE__)}/../config/#{CONFIGURATION}"

  namespace ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'production'

end
