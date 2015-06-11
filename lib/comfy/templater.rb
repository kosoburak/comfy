require 'settings'
require 'logger'
require 'tempfile'
require 'erb'
require 'fileutils'
require 'tmpdir'

module Comfy
  class Templater

    def initialize(data, logger)
      @data = data
      @logger = logger
    end

    # Prepares *.json and *.cfg files from templates for selected distribution
    def prepare_files
      distribution = @data[:distribution]
      template_dir = @data[:template_dir]
      server_dir = @data[:server_dir]

      @logger.debug('Creating temporary files...')
      cfg_tmp = Tempfile.new('comfy_cfg')
      json_tmp = Tempfile.new('comfy_json')
      @logger.debug("Temporary files '#{cfg_tmp.path}' and '#{json_tmp.path}' were created.")

      json_output = "#{server_dir}/#{distribution}.json"
      cfg_output = "#{server_dir}/#{distribution}.cfg"

      @logger.debug('Writing to temporary files...')
      write_to_tmp(json_tmp, populate_template("#{template_dir}/packer.erb"))
      write_to_tmp(cfg_tmp, populate_template("#{template_dir}/#{distribution}/#{distribution}.cfg.erb"))

      @logger.debug('Copying files to proper location...')
      FileUtils.cp(json_tmp.path, json_output)
      FileUtils.cp(cfg_tmp.path, cfg_output)

      @logger.debug('Cleaning temporary files...')
      json_tmp.close(true)
      cfg_tmp.close(true)
    end

    def write_to_tmp(tmp, data)
      tmp.write(data)
      tmp.flush
    end

    def populate_template(template)
      @logger.debug("Populating template '#{template}'")
      erb = ERB.new(File.read(template), nil, '-')
      erb.filename = template
      erb.result(binding)
    end
  end
end
