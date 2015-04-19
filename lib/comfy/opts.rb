require 'optparse'
require 'ostruct'
require 'pp'
require 'settings'

module Comfy
  # Class for parsing command line arguments
  class Opts
    FORMAT_DEFAULT = :qcow2
    SIZE_DEFAULT = 5000

    DIR = "#{GEM_DIR}/lib/templates"
    puts DIR

    # check templates directory for available distributions to create
    DISTROS = Dir.entries(DIR).select { |entry| entry != '.' && entry != '..' }
    # all expecting SHA256 checksums by default
    PARAMETERS = {}
    PARAMETERS['debian'] = 'version=7.8.0 checksum=e39c36d6adc0fd86c6edb0e03e22919086c883b37ca194d063b8e3e8f6ff6a3a'
    PARAMETERS['ubuntu'] = 'version=trusty checksum=bc09966b54f91f62c3c41fc14b76f2baa4cce48595ce22e8c9f24ab21ac8d965'
    PARAMETERS['sl'] = 'version=7.0 checksum=fd2e98c2c79b3d7e6e1211033de398e407c615300270aca22d7c8729121a27b3 release_date=2014-10-27'
    PARAMETERS['centos'] = 'version=7.1.1503 checksum=498bb78789ddc7973fe14358822eb1b48521bbaca91c17bd132c7f8c903d79b3'
    FORMATS = [:qcow2, :raw]

    # Return a structure with options
    def self.parse(args)

      options = OpenStruct.new
      options.params = {}

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage of COMFY tool: comfy.rb [options]'
        opts.separator ''

        opts.on('-d', '--distributions DISTRO1[,DISTRO2,...]', Array,
                'Select distributions for buliding. '\
              "Available distributions: #{DISTROS.join(', ')}. "\
              'Defaults to all available distributions.') do |list|
          options.distros = list
        end

        opts.on('-f', '--format [FORMAT]', FORMATS,
                'Select the output format of the virtual machine image (raw, qcow2). '\
              'Defaults to qcow2.') do |format|
          options.format = format
        end

        opts.on('-s', '--size [NUMBER]', Integer,
                'Specify disk size for created virtual machines (in MB). '\
              'Defaults to 5000MB (5GB)') do |size|
          options.size = size
        end

        DISTROS.each do |distro|
          opts.on("--#{distro} [PARAMETERS]",
                  "Specify parameters for building #{distro} virtual machine.") do |params|
            options.params[distro] = params if params
          end
        end

        opts.on_tail('-h', '--help', 'Shows this message') do
          puts opts
          exit
        end

        opts.on_tail('-v', '--version', 'Shows version') do
          puts ::Version.join('.')
          exit
        end
      end

      begin
        opt_parser.parse!(args)
      rescue OptionParser::ParseError => e
        puts e
        exit 1
      end

      set_defaults(options)
      check_files(options)
      check_options_restrictions(options)
      check_settings_restrictions

      options
    end

    # Set default values for not specified options
    def self.set_defaults(options)
      options.format = FORMAT_DEFAULT unless options.format
      options.size = SIZE_DEFAULT unless options.size
      options.distros = DISTROS unless options.distros

      options.distros.each do |distro|
        unless options.params.include? distro
          options.params[distro] = PARAMETERS[distro]
        end
      end
    end

    # Make sure we have templates
    def self.check_files(options)
      options.distros.each do |distro|
        dir = "#{DIR}/#{distro}"
        cfg = "#{dir}/#{distro}.cfg.erb"
        json = "#{dir}/#{distro}.json.erb"

        unless File.exists?(dir) && File.exists?(cfg) && File.exists?(json)
          fail ArgumentError, "Missing some configuration files for selected distribution #{distro}."
        end
      end
    end

    def self.check_options_restrictions(options)
      options.distros.each do |distro|
        unless DISTROS.include? distro
          options.params.delete distro
          options.distros.delete distro
          puts "Unknown distribution #{distro}. Will be skipped."
        end
      end

      if options.distros.empty?
        fail ArgumentError, 'No distributions to build.'
      end

      if options.size <= 0
        fail ArgumentError, 'Disk size cannot be 0 or less.'
      end

      unless FORMATS.include? options.format
        fail ArgumentError, 'Unknown file format.'
      end
    end

    def self.check_settings_restrictions
      #make sure output directory is set
      unless Settings['output'] && Settings.output['output_dir']
        fail ArgumentError, 'Missing output directory. Check your configuration file.'
      end

      #make sure packer cache directory is set
      unless Settings['packer_cache_dir']
        fail ArgumentError, 'Missing Packer cachce directory.'
      end
      ENV['PACKER_CACHE_DIR'] = Settings['packer_cache_dir']

      #make sure log file is specified while logging to file
      if Settings['logging'] && Settings.logging['log_type'] == 'file' &&
          !Settings.logging['log_file']
        fail ArgumentError, 'Missing file for logging. Check your configuration file.'
      end
    end
  end
end
