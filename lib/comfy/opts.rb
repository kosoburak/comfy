require 'optparse'
require 'ostruct'
require 'pp'
require 'settings'
require 'fileutils'
require 'json-schema'

module Comfy
  # Class for parsing command line arguments
  class Opts
    OPTION_PARSING_ERROR_EXIT_CODE = 1
    DIR = Settings['vm_templates_dir'] ? Settings['vm_templates_dir'] : "#{GEM_DIR}/lib/templates"
    FORMATS = [:qemu, :virtualbox]
    # defaults
    FORMAT_DEFAULT = FORMATS.first
    SIZE_DEFAULT = 5000
    DEBUG_DEFAULT = false
    PACKER_FILE = "#{DIR}/packer.erb"
    CREATE_DESCRIPTION = true
    VM_GROUPS = Settings['vm_groups']
    VM_IDENTIFIER_FORMAT = Settings['vm_identifier_format']

    # Return a structure with options
    def self.parse(args, logger)
      logger.debug("Template directory: #{DIR}.")

      options = OpenStruct.new

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage of COMFY tool: comfy [options] DISTRIBUTION'
        opts.separator ''

        opts.on('-V', '--distribution-version VERSION', 'Version of distribution to build. '\
                'Defaults to the newest version.') do |version|
          options.version = version
        end

        opts.on('-f', '--formats FORMAT1[,FORMAT2,...]', Array,
                'Select the output format of the virtual machine image (qemu - qcow2, virtualbox - ova). '\
                "Defaults to #{FORMAT_DEFAULT}.") do |formats|
          options.formats = formats
        end

        opts.on('-s', '--size NUMBER', Integer,
                'Specify disk size for created virtual machines (in MB). '\
                'Defaults to 5000MB (5GB)') do |size|
          options.size = size
        end

        opts.on('-l', '--list', 'Lists all the available distributions and their versions') do
          list_distributions
          exit
        end

        opts.on('-h', '--help', 'Shows this message') do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Shows version of COMFY') do
          puts Comfy::VERSION
          exit
        end

        opts.separator ''
        opts.separator 'Advanced options:'

        opts.on('--[no-]debug', 'Run in debug mode') do |flag|
          options.debug = flag
        end

        opts.on('--export DESTINATION', 'Exports files for building virtual machines to directory DESTINATION. '\
                'Helps with the customization of the build process.') do |dir|
          copy_templates(dir)
          exit
        end

        opts.on('--clean-cache', 'Cleans packer\'s cache containing distributions\' installation media.') do
          clean_cache
          exit
        end

        opts.on('--[no-]description','Do not create cloud appliance description file.') do |description|
          options.create_description = description
        end

        opts.on('--groups', Array, 'VM groups are filled into \'groups\' when generating cloud appliance descriptor.') do |groups|
          options.vm_groups = groups
        end

        opts.on('--vm-identifier','The format of VM\'s identifier') do |identifier|
          options.vm_identifier_format = identifier
        end
      end

      begin
        opt_parser.parse!(args)
        if ARGV.empty?
          puts 'Missing distribution to build'
          puts
          puts opt_parser
          exit OPTION_PARSING_ERROR_EXIT_CODE
        end
        options.distribution = ARGV.pop.downcase
      rescue OptionParser::ParseError => e
        puts e
        exit OPTION_PARSING_ERROR_EXIT_CODE
      end

      logger.debug("Parsed options: #{options}")

      set_defaults(options)
      check_files(options)
      check_options_restrictions(options)
      check_settings_restrictions

      fail ArgumentError, "vm_groups has to be set." unless Settings['vm_groups']

      options
    end

    def self.list_distributions
      distributions = Dir.entries(DIR).select { |entry| entry != '.' && entry != '..' && File.directory?("#{DIR}/#{entry}") }
      versions = []
      distributions.each do |distribution|
        description_file = "#{DIR}/#{distribution}/#{distribution}.description"
        # TODO prepared for json schema implementation
        # unless JSON::Validator.validate(DESCRIPTION_SCHEMA_FILE, description_file)
        unless true
          puts "Invalid schema for distribution #{distribution}, skipping."
          next
        end

        description = File.read(description_file)
        json = JSON.parse(description)
        name = json['name']
        json['versions'].each do |version|
          name_version = "#{name} #{version['major_version']}"
          name_version << ".#{version['minor_version']}" if version['minor_version']
          name_version << ".#{version['patch_version']}" if version['patch_version']
          versions << name_version
        end
      end

      versions.sort!
      versions.each { |version| puts version }
    end

    def self.copy_templates(dir)
      FileUtils.mkdir_p dir unless File.exist?(dir) && File.directory?(dir)

      FileUtils.cp_r "#{DIR}/.", dir
      puts 'Template files copied successfully.'
      puts "In order to use the new template directory change setting 'vm_templates_dir' in your configuration file to:"
      puts "vm_templates_dir: #{dir}"
    end

    def self.clean_cache
      check_settings_restrictions
      directory = Settings['packer_cache_dir']
      Dir.entries(directory).each { |entry| File.delete("#{directory}/#{entry}") unless entry == '.' || entry == '..' }
      puts 'Cache cleaned successfully.'
    end

    # Set default values for not specified options
    def self.set_defaults(options)
      options.formats ||= [FORMAT_DEFAULT]
      options.size ||= SIZE_DEFAULT
      options.debug ||= DEBUG_DEFAULT
      options.template_dir ||= DIR
      options.version ||= :newest
      options.create_description ||= CREATE_DESCRIPTION
      options.vm_groups ||= VM_GROUPS
      options.vm_identifier_format ||= VM_IDENTIFIER_FORMAT
    end

    # Make sure we have templates
    def self.check_files(options)
      unless File.exist?(PACKER_FILE)
        fail ArgumentError, 'Missing packer configuration file.'
      end

      distro = "#{options.distribution}"
      distro_dir = "#{DIR}/#{options.distribution}"
      distro_cfg = "#{distro_dir}/#{options.distribution}.cfg.erb"
      distro_description = "#{distro_dir}/#{options.distribution}.description"

      check_distro_dir(distro_dir, distro)
      check_distro_cfg(distro_cfg, distro)
      check_distro_description(distro_description, distro)

    end

    def self.check_distro_dir(distro_dir, distro)
      unless File.exist?(distro_dir)
        fail ArgumentError, "Missing directory for selected distribution - #{distro}."
      end
    end

    def self.check_distro_cfg(distro_cfg, distro)
      unless File.exist?(distro_cfg)
        fail ArgumentError, "Missing configuration file for selected distribution - #{distro}."
      end
    end

    def self.check_distro_description(distro_description, distro)
      unless File.exist?(distro_description)
        fail ArgumentError, "Missing description file for selected distribution - #{distro}."
      end
    end

    def self.check_options_restrictions(options)
      fail ArgumentError, 'Disk size cannot be 0 or less.' if options.size <= 0

      options.formats = options.formats.map(&:to_sym)
      if (FORMATS & options.formats).empty?
        fail ArgumentError, 'Unknown output format.'
      end
    end

    def self.check_settings_restrictions
      # make sure output directory is set
      unless Settings['output_dir']
        fail ArgumentError, 'Missing output directory. Check your configuration file.'
      end

      # make sure packer cache directory is set
      unless Settings['packer_cache_dir']
        fail ArgumentError, 'Missing Packer cachce directory.'
      end
      ENV['PACKER_CACHE_DIR'] = Settings['packer_cache_dir']
    end
  end
end
