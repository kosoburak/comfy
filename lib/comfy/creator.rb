require 'settings'
require 'fileutils'
require 'mixlib/shellout'
require 'tmpdir'
require 'json'

module Comfy
  class Creator

    def initialize(options, logger)
      @options = options
      @logger = logger
    end

    def create
      @logger.info('Preparing for image creation...')

      server_dir = Dir.mktmpdir('comfy')
      @options[:server_dir] = server_dir
      @logger.debug("Server root directory: #{server_dir}")

      distribution = @options[:distribution]
      template_dir = @options[:template_dir]

      prepare_data(distribution, template_dir)
      @logger.debug("Prepared data: #{@options}")

      templater = Comfy::Templater.new(@options, @logger)
      templater.prepare_files

      packer_file = "#{server_dir}/#{distribution}.json"

      @logger.info("Calling Packer - building distribution: '#{distribution}'.")
      packer = Mixlib::ShellOut.new("packer validate #{packer_file}")
      packer.run_command
      if packer.error?
        @logger.error("Packer validation failed: #{packer.stdout}")
        clean(server_dir)
        exit(2)
      end

      packer = Mixlib::ShellOut.new("packer build -parallel=false #{packer_file}", :timeout => 5400)
      packer.live_stream = @logger
      packer.run_command

      if packer.error?
        @logger.error("Packer finished with error for distribution '#{distribution}': #{packer.stderr}")
      else
        @logger.info("Packer finished successfully for distribution '#{distribution}'")
      end

      clean(server_dir)
    end

    def prepare_data(distribution, template_dir)
      description = File.read("#{template_dir}/#{distribution}/#{distribution}.description")
      @options[:distro] = JSON.parse(description)
      @logger.debug("Data from description file: #{@options[:distro]}")

      @options[:distro][:version] = choose_version

      @options[:provisioners] = {}
      @options[:provisioners][:scripts] = get_group(template_dir, distribution, 'scripts')
      @options[:provisioners][:files] = get_group(template_dir, distribution, 'files')

      @options[:password] = password
      @logger.debug("Temporary password: '#{@options[:password]}'")
    end

    def choose_version
      version = @options[:version]

      available_versions = @options[:distro]['versions']
      available_versions.sort_by! { |e| [e['major_version'], e['minor_version'], e['patch_version']] }.reverse!

      if version == :newest
        return available_versions.first
      end

      version_parts = version.split('.')
      if version_parts.size > 3
        @logger.error("No version #{version} available for #{@options[:distribution]}")
        clean(@options[:server_dir])
        exit(3)
      end

      selected = available_versions.select { |e| e['major_version'] == version_parts[0] }
      if version_parts.size > 1
        selected = selected.select { |e| e['minor_version'] == version_parts[1] }

        if version_parts.size > 2
          selected = selected.select { |e| e['patch_version'] == version_parts[2] }
        end
      end

      if selected.empty?
        @logger.error("No version #{version} available for #{@options[:distribution]}")
        clean(@options[:server_dir])
        exit(3)
      end

      selected.sort.reverse.first
    end

    def clean(server_dir)
      @logger.debug('Cleaning temporary directory...')
      #FileUtils.remove_dir(server_dir)
    end

    def get_group(template_dir, distro, group_name)
      group = []
      group_dir_path = "#{template_dir}/#{distro}/#{group_name}"
      return group unless Dir.exist? group_dir_path
      group_dir = Dir.new(group_dir_path)
      group_dir.entries.select { |entry| entry != '.' && entry != '..' }.each do |file|
        group << "#{group_dir.path}/#{file}"
      end

      group
    end

    def password
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      (0...100).map { o[rand(o.length)] }.join
    end
  end
end

