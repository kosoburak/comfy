module Comfy
  GEM_DIR = File.realdirpath(File.join(File.dirname(__FILE__), '..'))
  DESCRIPTOR_SCHEMA_FILE = File.join(GEM_DIR, 'schema', 'distribution_descriptor.schema')
  require 'comfy/version'
  require 'comfy/templater'
  require 'comfy/opts'
  require 'comfy/creator'
end
