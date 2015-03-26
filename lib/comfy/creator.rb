require 'settings'
require 'fileutils'
require 'mixlib/shellout'
require 'tmpdir'

module Comfy
  class Creator

    def initialize(options, logger)
      @options = options
      @logger = logger
    end

    def create
      @logger.info('Preparing for images creation...')

      server_dir = Dir.mktmpdir('comfy')

      @logger.debug("Server root directory: #{server_dir}")

      template_options = @options.select { |k, v| k == :format || k == :size }
      templater = Comfy::Templater.new(server_dir, template_options, @logger)

      @options[:distros].each do |distro|
        templater.prepare_files(distro, @options[:params][distro])

        @logger.info("Calling Packer - building distribution: '#{distro}'.")
        packer = Mixlib::ShellOut.new("packer validate #{server_dir}/#{distro}.json")
        packer.run_command
        if packer.error?
          @logger.error("Packer validation failed: #{packer.stdout}")
          FileUtils.rm(["#{server_dir}/#{distro}.json", "#{server_dir}/#{distro}.cfg"])
          next
        end

        packer = Mixlib::ShellOut.new("packer build #{server_dir}/#{distro}.json", :timeout => 5400)
        packer.live_stream = @logger
        packer.run_command

        if packer.error?
          @logger.error("Packer finished with error for distribution '#{distro}': #{packer.stderr}")
        else
          @logger.info("Packer finished successfully for distribution '#{distro}'")
        end

        FileUtils.rm(["#{server_dir}/#{distro}.json", "#{server_dir}/#{distro}.cfg"])
      end

      @logger.info('All distributions finished.')
      clean(server_dir)
    end

    def clean(server_dir)
      @logger.debug('Cleaning temporary directory...')
      FileUtils.remove_dir("#{server_dir}")
    end
  end
end

