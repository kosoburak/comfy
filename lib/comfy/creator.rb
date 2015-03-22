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
      @logger.info('Starting local webserver...')

      server_dir = Dir.mktmpdir('comfy')
      Dir.mkdir("#{server_dir}/public")
      server = Mixlib::ShellOut.new("thin -p 4242 -P #{Dir.tmpdir}/thin.pid -l /dev/null -d start", :cwd => "#{GEM_DIR}/server", :env => {"comfy_server_public" => "#{server_dir}/public"})
      server.run_command
      if server.error?
        @logger.error("Error occurred during server start. Aborting.")
        FileUtils.remove_dir("#{server_dir}")
        exit 1
      end

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
          FileUtils.rm(["#{server_dir}/#{distro}.json", "#{server_dir}/public/#{distro}.cfg"])
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

        FileUtils.rm(["#{server_dir}/#{distro}.json", "#{server_dir}/public/#{distro}.cfg"])
      end

      @logger.info('All distributions finished.')
      @logger.info('Stopping local webserver...')
      server = Mixlib::ShellOut.new("thin -P #{Dir.tmpdir}/thin.pid stop", :cwd => "#{GEM_DIR}/server")
      server.run_command
      if server.error?
        @logger.error("Error occurred during stopping the server. Process my be still running. Server's PID file is '#{Dir.tmpdir}/thin.pid'")
      end

      @logger.debug('Cleaning temporary directory...')
      FileUtils.remove_dir("#{server_dir}")
    end
  end
end

