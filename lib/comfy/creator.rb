require 'fileutils'
require 'mixlib/shellout'
require 'tmpdir'
require 'json'
require 'json-schema'
require 'cloud-appliance-descriptor'

# Creates given virtual machine images.
class Comfy::Creator
  attr_accessor :data

  TIMESTAMP_FORMAT = '%Y%m%d%H%M'

  NEEDLE_REPLACEMENTS = {
    :$v => lambda { |instance| instance.send(:version_string) },
    :$t => lambda { |instance| Time.new.strftime(TIMESTAMP_FORMAT) },
    :$n => lambda { |instance| instance.data[:distro]['name'] },
    :$g => lambda { |instance| instance.data[:groups].join(',') }
  }
  REPLACEMENT_REGEX = /\$[a-zA-Z]/

  # Creates a creator instance.
  #
  # @param options [Hashie::Mash] hash-like structure with options
  def initialize(options)
    @data = options.clone
  end

  # Method representing the whole creation process. Prepares enviroment,
  # prepare files and starts packer job.
  def create
    logger.info('Preparing for image creation...')

    data[:server_dir] = Dir.mktmpdir('comfy')
    logger.debug("Server root directory: #{data[:server_dir]}")

    prepare_data
    logger.debug("Prepared data: #{data}")

    templater = Comfy::Templater.new data
    templater.prepare_files

    packer_file = "#{data[:server_dir]}/#{data[:distribution]}.packer"
    run_packer(packer_file)

    # let's create cloud appliance descriptor files
    if data[:description]
      data[:formats].each do |format|
        name = data[:distribution]
        major = data[:distro][:version]['major_version']
        minor = data[:distro][:version]['minor_version']
        dir = File.join(data[:'output-dir'], "comfy_#{name}-#{major}.#{minor}_#{format}/")
        File.write(File.join(dir, "#{data[:identifier]}.json"), description(format))
      end
    end
  end

  # Cleans everything from temporary directory
  def clean
    if data[:server_dir]
      logger.debug("Cleaning temporary directory #{data[:server_dir]}.")
      FileUtils.remove_dir(data[:server_dir])
    end
  end

  private

  # Method wrapping usage of packer tool.
  #
  # @param packer_file descriptor file with info for packer processing.
  def run_packer(packer_file)
    logger.info("Calling Packer - building distribution: '#{data[:distribution]}'.")

    packer_binary = data[:'packer-binary'] || 'packer'

    packer = Mixlib::ShellOut.new(packer_binary, "validate", packer_file)
    packer.run_command

    fail Comfy::Errors::PackerValidationError, "Packer validation failed for distribution '#{data[:distribution]}': #{packer.stdout}" if packer.error?

    packer = Mixlib::ShellOut.new(packer_binary, "build", "-parallel=false", packer_file, timeout: 5400)
    packer.live_stream = logger
    packer.run_command

    fail Comfy::Errors::PackerExecutionError, "Packer finished with error for distribution '#{data[:distribution]}': #{packer.stderr}" if packer.error?

    logger.info("Packer finished successfully for distribution '#{data[:distribution]}'")
  end

  # Preparation of various data. Method prepares description file for packer and distribution
  # preseed / kickstart file.
  def prepare_data
    description_file = "#{data[:'template-dir']}/#{data[:distribution]}/#{data[:distribution]}.description"
    JSON::Validator.validate!(Comfy::DESCRIPTION_SCHEMA_FILE, description_file)

    description = File.read(description_file)
    data[:distro] = JSON.parse(description)
    logger.debug("Data from description file: #{data[:distro]}")

    data[:distro][:version] = choose_version
    logger.debug("Version selected for build: #{data[:distro][:version]}")

    data[:provisioners] = {}
    data[:provisioners][:scripts] = Dir.glob(File.join(data[:'template-dir'], data[:distribution], 'scripts', '*'))
    data[:provisioners][:files] = Dir.glob(File.join(data[:'template-dir'], data[:distribution], 'files', '*'))

    data[:password] = password
    logger.debug("Temporary password: '#{data[:password]}'")

    data[:identifier] = replace_needles(data[:identifier])
  end

  # Choose_version is a method that selects required version from available versions.
  def choose_version
    version = data[:version]

    available_versions = []
    data[:distro]['versions'].each do |v|
      available_versions << { major: v['major_version'].to_i, minor: v['minor_version'].to_i, patch: v['patch_version'].to_i, version: v }
    end
    available_versions.sort_by! { |v| [v[:major], v[:minor], v[:patch]] }.reverse!

    return available_versions.first[:version] if version == :newest

    version_parts = version.split('.')
    fail Comfy::Errors::InvalidDistributionVersionError, "Version '#{version}' is not a valid distribution version" if version_parts.size > 3

    version_parts.map! do |part|
      fail Comfy::Errors::InvalidDistributionVersionError, "Version '#{version}' is not a valid distribution version" unless part =~ /\A\d+\z/

      part.to_i
    end

    selected = available_versions.select { |v| v[:major] == version_parts[0] }
    if version_parts.size > 1
      selected = selected.select { |v| v[:minor] == version_parts[1] }

      if version_parts.size > 2
        selected = selected.select { |v| v[:patch] == version_parts[2] }
      end
    end

    fail Comfy::Errors::NoSuchDistributionVersionError, "No version '#{version}' available for distribution '#{data[:distribution]}'" if selected.empty?

    selected.sort_by { |v| [v[:major], v[:minor], v[:patch]] }.reverse.first[:version]
  end

  # Method generating a temporary random password used while creating image.
  #
  # @return [String] password
  def password
    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    (0...100).map { o[rand(o.length)] }.join
  end

  # Description returns cloud appliance descriptor JSON. It uses information gathered from command line arguments
  # and the config file.
  #
  # @param builder [Symbol] builder used in the description of the cloud appliance descriptor
  #
  # @return [Json] appliance descriptor in Json format
  def description(builder)
    # FIXME? mapping platforms/builders to formats is hardcoded for now, nothing else is supported
    formats = { 'virtualbox' => 'ova', 'qemu' => 'qcow2' }
    vm_dir = "comfy_#{data[:distribution]}-#{data[:distro][:version]['major_version']}.#{data[:distro][:version]['minor_version']}_#{builder}"
    vm_name = "#{vm_dir}.#{formats[builder]}"
    disk_path = File.join(data[:'output-dir'],vm_dir,vm_name)

    os = Cloud::Appliance::Descriptor::Os.new distribution: data[:distribution], version: version_string
    disk = Cloud::Appliance::Descriptor::Disk.new type: :os, format: formats[builder], path: disk_path

    appliance = Cloud::Appliance::Descriptor::Appliance.new action: :registration, os: os, disks: [disk]
    appliance.title = data[:distro]['name']
    appliance.identifier = data[:identifier]
    appliance.version = Time.new.strftime(TIMESTAMP_FORMAT)
    appliance.groups = data[:groups]

    appliance.to_json
  end

  # Replace needles in the argument.
  # Replacements are picked from NEEDLE_REPLACEMENTS constant.
  #
  # @param [String] format_string string with needles to be replaced
  #
  # @return [String] format_string with all needles replaced
  def replace_needles(format_string)
    format_string.gsub(REPLACEMENT_REGEX) do |match|
      NEEDLE_REPLACEMENTS.key?(match.to_sym) ? NEEDLE_REPLACEMENTS[match.to_sym].call(self) : match
    end
  end

  # Simple method used to return the version string
  #
  # @return [String] string which contains major, minor, and patch version (if possible).
  def version_string
    result = []
    result << data[:distro][:version]['major_version']
    result << data[:distro][:version]['minor_version']
    result << data[:distro][:version]['patch_version']
    result.compact.join('.')
  end
end
