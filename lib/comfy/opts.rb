require 'optparse'
require 'ostruct'
require 'pp'
require 'settings'
require 'fileutils'

module Comfy
  # Class for parsing command line arguments
  class Opts
    DIR = Settings['vm_templates_dir'] ? Settings['vm_templates_dir'] : "#{GEM_DIR}/lib/templates"
    FORMATS = [:qemu, :virtualbox]
    # defaults
    FORMAT_DEFAULT = FORMATS.first
    SIZE_DEFAULT = 5000
    DEBUG_DEFAULT = false

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
      end

      begin
        opt_parser.parse!(args)
        if ARGV.empty?
          puts 'Missing distribution to build'
          puts
          puts opt_parser
          exit 1
        end
        options.distribution = ARGV.pop.downcase
      rescue OptionParser::ParseError => e
        puts e
        exit 1
      end

      logger.debug("Parsed options: #{options}")

      set_defaults(options)
      check_files(options)
      check_options_restrictions(options)
      check_settings_restrictions

      options
    end

    def self.list_distributions
      distributions = Dir.entries(DIR).select { |entry| entry != '.' && entry != '..' && File.directory?("#{DIR}/#{entry}") }
      versions = []
      distributions.each do |distribution|
        description = File.read("#{DIR}/#{distribution}/#{distribution}.description")
        json = JSON.parse(description)
        name = json['name']
        json['versions'].each do |version|
          name_version = "#{name} #{version['major_version']}.#{version['minor_version']}"
          name_version << ".#{version['patch_version']}" if version['patch_version']
          versions << name_version
        end
      end

      versions.sort!
      versions.each { |version| puts version}
    end

    def self.copy_templates(dir)
      unless File.exists?(dir) && File.directory?(dir)
        FileUtils.mkdir_p dir
      end

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
    end

    # Make sure we have templates
    def self.check_files(options)
      packer_file = "#{DIR}/packer.erb"

      unless File.exists?(packer_file)
        fail ArgumentError, 'Missing packer configuration file.'
      end

      distro_dir = "#{DIR}/#{options.distribution}"
      distro_cfg = "#{distro_dir}/#{options.distribution}.cfg.erb"
      distro_description = "#{distro_dir}/#{options.distribution}.description"

      unless File.exists?(distro_dir) && File.exists?(distro_cfg) && File.exists?(distro_description)
        fail ArgumentError, "Missing some configuration files for selected distribution #{options.distribution}."
      end
    end

    def self.check_options_restrictions(options)
      if options.size <= 0
        fail ArgumentError, 'Disk size cannot be 0 or less.'
      end

      options.formats = options.formats.map { |format| format.to_sym}
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
