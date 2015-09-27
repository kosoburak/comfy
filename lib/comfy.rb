module Comfy
  GEM_DIR = File.realdirpath(File.join(File.dirname(__FILE__), '..'))
  DESCRIPTION_SCHEMA_FILE = File.join(GEM_DIR, 'schema', 'distribution_descriptor.schema')

  # exit codes
  DEFAULT_EXIT_CODE = 0
  OPTION_PARSING_ERROR_EXIT_CODE = 1
  JSON_SCHEMA_VALIDATION_ERROR_EXIT_CODE = 2
  PACKER_VALIDATION_ERROR_EXIT_CODE = 3
  PACKER_EXECUTION_ERROR_EXIT_CODE = 4
  INVALID_DISTRIBUTION_VERSION_ERROR_EXIT_CODE = 5
  NO_SUCH_DISTRIBUTION_VERSION_ERROR_EXIT_CODE = 6

  require 'active_support/all'

  require 'comfy/version'
  require 'comfy/templater'
  require 'comfy/opts'
  require 'comfy/creator'
  require 'comfy/errors'
end
