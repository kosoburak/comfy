require 'thor'
require 'yell'
require 'json-schema'
require 'fileutils'

class Comfy::CommandExecutioner < Thor
  class << self
    
    # Method listing available distributions from template directory.
    #
    # @return [Hash] distributions structure containing info about them
    def available_distributions
      dir = Comfy::TEMPLATE_DIR
      return {} unless File.exist? dir

      description_files = Dir.glob(File.join(dir, '*', '*.description')).sort
      distributions  = {}
      description_files.each do |description_file|
        unless JSON::Validator.validate(Comfy::DESCRIPTION_SCHEMA_FILE, description_file)
          puts "Invalid distribution description #{description_file.inspect}, skipping."
          next
        end

        description = File.read(description_file)
        json = JSON.parse(description)
        name = json['name']
        distributions[name] = []
        json['versions'].each do |version|
          version_string = []
          version_string << version['major_version']
          version_string << version['minor_version']
          version_string << version['patch_version']

          distributions[name] << version_string.compact.join('.')
          distributions[name].sort!
        end
      end

      distributions
    end
  end

  class_option :"logging-level",
                :required => true,
                :default => Comfy::Settings['logging']['level'],
                :type => :string,
                :enum => Yell::Severities
  class_option :"logging-file",
                :default => Comfy::Settings['logging']['file'],
                :type => :string,
                :desc => 'File to write log to'
  class_option :debug,
                :default => Comfy::Settings['debug'],
                :type => :boolean,
                :desc => 'Runs COMFY in debug mode'

  desc 'version', 'Prints COMFY\'s version'
  def version
    $stdout.puts Comfy::VERSION
  end

  desc 'distributions', 'Lists all available distributions and their versions'
  def distributions
    self.class.available_distributions.each do |distribution, versions|
      versions.each { |version| $stdout.puts "#{distribution} #{version}" }
    end
  end

  method_option :destination,
                type: :string,
                required: true,
                aliases: '-d',
                desc: 'Destination of exported files'
  desc 'export', 'Exports files for building virtual machines. Helps with the customization of the build process.'
  def export
    dir = options['destination']
    FileUtils.mkdir_p dir unless File.exist?(dir) && File.directory?(dir)

    FileUtils.cp_r(File.join(Comfy::Settings['template-dir'], '.'), dir)
    $stdout.puts 'Template files copied successfully.'
    $stdout.puts "In order to use the new template directory change setting 'vm_templates_dir' in your configuration file to:"
    $stdout.puts "template-dir: #{dir}"
  end

  method_option :"cache-dir",
                type: :string,
                required: true,
                default: Comfy::Settings['cache-dir'],
                aliases: '-c',
                desc: 'Directory for packer\'s cache e.g. distribution installation images'
  desc 'clean-cache', 'Cleans packer\'s cache containing distributions\' installation media'
  def clean_cache
    dir = options['cache-dir']
    FileUtils.rm_r Dir.glob(File.join(dir, '*'))
    puts 'Cache cleaned successfully.'
  end

  available_distributions.each do |name, versions|
    plain_name = name.downcase
    method_option :version,
                  type: :string,
                  aliases: '-v',
                  default: versions.first,
                  required: true,
                  desc: 'Version of distribution to build'
    method_option :formats,
                  type: :array,
                  aliases: '-f',
                  default: Comfy::Settings['formats'],
                  enum: ['qemu', 'virtualbox'],
                  required: true,
                  desc: 'Output format of the virtual machine image (qemu - qcow2, virtualbox - ova)'
    method_option :size,
                  type: :numeric,
                  aliases: '-s',
                  default: Comfy::Settings['size'],
                  required: true,
                  desc: 'Disk size for created virtual machines (in MB)'
    method_option :"output-dir",
                  type: :string,
                  required: true,
                  default: Comfy::Settings['output-dir'],
                  aliases: '-o',
                  desc: 'Directory to which COMFY will produce virtual machine files'
    method_option :"cache-dir",
                  type: :string,
                  required: true,
                  default: Comfy::Settings['cache-dir'],
                  aliases: '-c',
                  desc: 'Directory for packer\'s cache e.g. distribution installation images'
    method_option :groups,
                  type: :array,
                  aliases: '-g',
                  default: Comfy::Settings['groups'],
                  desc: 'Groups VM belongs to. For automatic processing purposes'
    method_option :identifier,
                  type: :string,
                  aliases: '-i',
                  default: Comfy::Settings['identifier'],
                  desc: 'VM identifier. For automatic processing purposes'
    method_option :description,
                  type: :boolean,
                  aliases: '-d',
                  default: Comfy::Settings['description'],
                  desc: 'Generates VM description file. For automatic processing purposes'
    method_option :'template-dir',
                  type: :string,
                  aliases: '-t',
                  default: Comfy::TEMPLATE_DIR,
                  desc: 'Directory COMFY uses templates from to build a VM'

    class_eval %Q^
desc '#{plain_name}', 'Builds VM with distribution #{name}'
def #{plain_name}
  start('#{plain_name}', options)
end

desc '#{plain_name}-versions', 'Lists all available versions of #{name}'
def #{plain_name}_versions
  #{versions}.each { |version| $stdout.puts version }
end
^
  end

  private

  def start(distribution_name, options)
    parameters = options.to_hash.deep_symbolize_keys
    parameters[:distribution] = distribution_name
    parameters[:headless] = !parameters[:debug]
    ENV['PACKER_CACHE_DIR'] = parameters[:'cache-dir']

    init_log parameters
    check_distribution_files distribution_name

    logger.debug "Parameters: #{parameters}"

    begin
      creator = Comfy::Creator.new(parameters)
      creator.create
    ensure
      creator.clean
    end
  end

  # Inits logging according to the settings
  #
  # @param [Hash] parameters
  # @option parameters [String] logging-level
  # @option parameters [String] logging-file file to log to
  # @option parameters [TrueClass, FalseClass] debug debug mode
  # @return [Type] description of returned object
  def init_log(parameters)
    if parameters[:debug]
      parameters[:'logging-level'] = 'DEBUG'
      ENV['PACKER_LOG'] = '1'
    end

    Yell.new :stdout, :name => Object, :level => parameters[:'logging-level'].downcase, :format => Yell::DefaultFormat
    Object.send :include, Yell::Loggable

    if parameters[:'logging-file']
      unless (File.exist?(parameters[:'logging-file']) && File.writable?(parameters[:'logging-file'])) || (File.writable?(File.dirname(parameters[:'logging-file'])))
        logger.error "File #{parameters[:'logging-file']} isn't writable"
        return
      end

      logger.adapter :file, parameters[:'logging-file']
    end
  end

  def check_distribution_files(distribution_name)
    distribution_cfg = File.join(Comfy::TEMPLATE_DIR, distribution_name, "#{distribution_name}.cfg.erb")
    unless File.exist?(distribution_cfg)
      logger.error "Missing distribution configuration #{distribution_cfg.inspect}, cannot build VM"
      exit
    end

    distribution_desc = File.join(Comfy::TEMPLATE_DIR, distribution_name, "#{distribution_name}.description")
    unless File.exist?(distribution_desc)
      logger.error "Missing distribution description #{distribution_desc.inspect}, cannot build VM"
      exit
    end
  end
end
