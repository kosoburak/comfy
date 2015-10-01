module Comfy
  GEM_DIR = File.realdirpath(File.join(File.dirname(__FILE__), '..'))
  DESCRIPTION_SCHEMA_FILE = File.join(GEM_DIR, 'schema', 'distribution_descriptor.schema')

  require 'active_support/all'

  require 'comfy/version'
  require 'comfy/templater'
  require 'comfy/opts'
  require 'comfy/creator'
  require 'comfy/errors'
end
