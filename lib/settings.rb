require 'settingslogic'

class Settings < Settingslogic
  CONFIGURATION = 'conf.yml'

#three possible configuration file locations in order by preference
#if configuration file is found rest of the locations are ignored
  source "#{ENV['HOME']}/.comfy/#{CONFIGURATION}"\
if File.exist?("#{ENV['HOME']}/.comfy/#{CONFIGURATION}")
  source "/etc/comfy/#{CONFIGURATION}"\
if File.exist?("/etc/comfy/#{CONFIGURATION}")
  source "#{File.dirname(__FILE__)}/../config/#{CONFIGURATION}"

  namespace 'production'
end
