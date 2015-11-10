require 'thor'
require 'fileutils'

class Comfy::CommandExecutioner < Thor
  class << self
    def available_distributions
      dir = Settings['vm_templates_dir']
      return {} unless File.exist? dir

      descriptions = Dir.glob(File.join(dir, '*', '*.description')).sort
      distributions  = {}
      descriptions.each do |descriptrion|
        unless JSON::Validator.validate(DESCRIPTION_SCHEMA_FILE, description_file)
          puts "Invalid distribution description #{descriptrion.inspect}, skipping."
          next
        end

        description = File.read(description_file)
        json = JSON.parse(description)
        name = json['name']
        distributions[name] = []
        json['versions'].each do |version|
          version = []
          version << version['major_version']
          version << version['minor_version']
          version << version['patch_version']

          distributions[name] << version.compact.join('.')
        end
      end

      distributions
    end
  end

  desc 'distributions', 'List all available distributions and their versions'
  def distributions
    available_distributions.each do |distribution, versions|
      versions.each { |version| $stdout.puts "#{distribution} #{version}" }
    end
  end

  method_option :destination,
                :type => :string,
                :required => true,
                :aliases => '-d',
                :desc => 'Destination of exported files'
  desc 'export', 'Exports files for building virtual machines. Helps with the customization of the build process.'
  def export
    dir = options['destination']
    FileUtils.mkdir_p dir unless File.exist?(dir) && File.directory?(dir)

    FileUtils.cp_r(File.join(Settings['vm_templates_dir'], '.'), dir)
    $stdout.puts 'Template files copied successfully.'
    $stdout.puts "In order to use the new template directory change setting 'vm_templates_dir' in your configuration file to:"
    $stdout.puts "vm_templates_dir: #{dir}"
  end

  method_option :"cache-directory",
                :type => :string,
                :required => true,
                :default => Settings['cache-directory'],
                :aliases => '-c',
                :desc => 'Directory for packer\'s cache e.g. distribution installation images'
  desc 'clean-cache', 'Cleans packer\'s cache containing distributions\' installation media'
  def clean_cache
    dir = options['cache-directory']
    FileUtils.rm_r Dir.glob(File.join(dir, '*'))
    puts 'Cache cleaned successfully.'
  end


end
