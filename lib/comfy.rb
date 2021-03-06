module Comfy
  require 'comfy/settings'

  GEM_DIR = File.realdirpath(File.join(File.dirname(__FILE__), '..'))
  DESCRIPTION_SCHEMA_FILE = File.join(GEM_DIR, 'schema', 'distribution_descriptor.schema')
  TEMPLATE_DIR = Comfy::Settings['template-dir'] || File.join(GEM_DIR, 'lib', 'templates')
  PACKER_FILE = File.join(TEMPLATE_DIR, 'packer.erb')

  require 'active_support/all'

  require 'comfy/extensions/yell'

  require 'comfy/command_executioner'
  require 'comfy/version'
  require 'comfy/templater'
  require 'comfy/creator'
  require 'comfy/errors'
end
