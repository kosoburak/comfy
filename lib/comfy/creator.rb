require 'settings'
require 'fileutils'
require 'mixlib/shellout'
require 'tmpdir'
require 'json'
require 'json-schema'

class Comfy::Creator
  attr_accessor :data
  attr_reader :logger

  def initialize(options, logger)
    @data = options.clone
    @logger = logger
  end

  def create
    logger.info('Preparing for image creation...')

    data[:server_dir] = Dir.mktmpdir('comfy')
    logger.debug("Server root directory: #{data[:server_dir]}")

    prepare_data
    logger.debug("Prepared data: #{data}")

    templater = Comfy::Templater.new(data, logger)
    templater.prepare_files

    packer_file = "#{data[:server_dir]}/#{data[:distribution]}.json"
    run_packer(packer_file)
  end

  def run_packer(packer_file)
    logger.info("Calling Packer - building distribution: '#{data[:distribution]}'.")
    packer = Mixlib::ShellOut.new("packer validate #{packer_file}")
    packer.run_command

    raise Comfy::Errors::PackerValidationError, "Packer validation failed for distribution '#{data[:distribution]}': #{packer.stdout}" if packer.error?

    packer = Mixlib::ShellOut.new("packer build -parallel=false #{packer_file}", timeout: 5400)
    packer.live_stream = logger
    packer.run_command

    raise Comfy::Errors::PackerExecutionError, "Packer finished with error for distribution '#{data[:distribution]}': #{packer.stderr}" if packer.error?

    logger.info("Packer finished successfully for distribution '#{data[:distribution]}'")
  end

  def prepare_data
    description_file = "#{data[:template_dir]}/#{data[:distribution]}/#{data[:distribution]}.description"

    description = File.read(description_file)
    data[:distro] = JSON.parse(description)
    logger.debug("Data from description file: #{data[:distro]}")

    data[:distro][:version] = choose_version

    data[:provisioners] = {}
    data[:provisioners][:scripts] = get_group(template_dir, distribution, 'scripts')
    data[:provisioners][:files] = get_group(template_dir, distribution, 'files')

    data[:password] = password
    logger.debug("Temporary password: '#{data[:password]}'")
  end

  def choose_version
    version = data[:version]

    available_versions = data[:distro]['versions']
    available_versions.sort_by! { |e| [e['major_version'], e['minor_version'], e['patch_version']] }.reverse!

    return available_versions.first if version == :newest

    version_parts = version.split('.')
    if version_parts.size > 3
      logger.error("No version #{version} available for #{data[:distribution]}")
      clean(data[:server_dir])
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
      logger.error("No version #{version} available for #{data[:distribution]}")
      clean(data[:server_dir])
      exit(3)
    end

    selected.sort.reverse.first
  end

  def clean
    if data[:server_dir]
      logger.debug("Cleaning temporary directory #{data[:server_dir]}.")
      FileUtils.remove_dir(data[:server_dir])
    end
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
    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    (0...100).map { o[rand(o.length)] }.join
  end
end
