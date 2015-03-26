require 'settings'
require 'logger'
require 'tempfile'
require 'erb'
require 'fileutils'
require 'tmpdir'

module Comfy
  class Templater

    def initialize(server_dir, options, logger)
      @common_data = {}
      @common_data[:format] = options[:format]
      @common_data[:size] = options[:size]
      @common_data[:output_dir] = Settings.output['output_dir']
      @server_dir = server_dir
      @logger = logger
      @distro_data = {}
    end

    # Prepares *.json and *.cfg files from templates for selected distribution
    def prepare_files(distro, parameters)
      @data = prepare_data(distro, parameters)
      @data[:server_dir] = @server_dir

      @logger.debug('Creating temporary files...')
      cfg_tmp = Tempfile.new('comfy_cfg')
      json_tmp = Tempfile.new('comfy_json')
      @logger.debug("Temporary files '#{cfg_tmp.path}' and '#{json_tmp.path}' were created.")

      @logger.debug('Generating temporary password...')
      @data[:password] = password
      @logger.debug("Temporary password: '#{@data[:password]}'")

      json_output = "#{@server_dir}/#{distro}.json"
      cfg_output = "#{@server_dir}/#{distro}.cfg"

      template_path = "#{GEM_DIR}/lib/templates/#{distro}"

      @logger.debug('Writing to temporary files...')
      write_to_tmp(json_tmp, populate_template("#{template_path}/#{distro}.json.erb"))
      write_to_tmp(cfg_tmp, populate_template("#{template_path}/#{distro}.cfg.erb"))

      @logger.debug('Copying files to proper location...')
      FileUtils.cp(json_tmp.path, json_output)
      FileUtils.cp(cfg_tmp.path, cfg_output)

      @logger.debug('Cleaning temporary files...')
      json_tmp.close(true)
      cfg_tmp.close(true)
    end

    def prepare_data(distro, parameters)
      distro_data = @common_data.clone
      distro_data[:parameters] = parse_parameters parameters
      distro_data[:provisioners] = {}
      distro_data[:provisioners][:scripts] = get_group('scripts', distro)
      distro_data[:provisioners][:files] = get_group('files', distro)

      distro_data
    end

    def parse_parameters(parameters_string)
      parameters = {}
      parameters_array = parameters_string.split
      parameters_array.each do |pair_string|
        pair = pair_string.split('=')
        unless pair.size == 2
          @logger.warn("Cannot parse parameter #{pair_string}. Parameters must have format 'key=value'.")
          next
        end
        parameters[pair[0].to_sym] = pair[1]
      end

      parameters
    end

    def get_group(group_name, distro)
      group = []
      group_dir_path = "#{GEM_DIR}/lib/templates/#{distro}/#{group_name}"
      return group unless Dir.exist? group_dir_path
      group_dir = Dir.new(group_dir_path)
      group_dir.entries.select { |entry| entry != '.' && entry != '..' }.each do |file|
        group << "#{group_dir.path}/#{file}"
      end

      group
    end

    def write_to_tmp(tmp, data)
      tmp.write(data)
      tmp.flush
    end

    def password
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      (0...100).map { o[rand(o.length)] }.join
    end

    def populate_template(template)
      @logger.debug("Populating template '#{template}'")
      erb = ERB.new(File.read(template), nil, '-')
      erb.filename = template
      erb.result(binding)
    end
  end
end
