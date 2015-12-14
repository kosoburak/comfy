require 'tempfile'
require 'erb'
require 'fileutils'
require 'tmpdir'

# Class used for preparing and filling file templates.
class Comfy::Templater
  attr_reader :data

  # Creates an instance of Templater.
  #
  # @param data [Hash] prepared data with distro, provisioners, files, password and identifier info.
  def initialize(data)
    @data = data
  end

  # Prepares *.json and *.cfg files from templates for selected distribution
  def prepare_files
    prepare_file('cfg')
    prepare_file('packer', true)
  end

  private

  # Method prepares .erb file with given data.
  #
  # @param name [String] type of file for preparation.
  # @param packer [Boolean] (implicite value = false).
  def prepare_file(name, packer = false)
    logger.debug("Creating temporary #{name} file...")
    tmp = Tempfile.new("comfy_#{name}")
    logger.debug("Temporary file '#{tmp.path}' was created.")

    output = File.join(data[:server_dir], "#{data[:distribution]}.#{name}")

    logger.debug("Writing to temporary #{name} file...")
    template_path = File.join(data[:'template-dir'], data[:distribution], "#{data[:distribution]}.#{name}.erb")
    template_path = File.join(data[:'template-dir'], 'packer.erb') if packer
    write_to_tmp(tmp, populate_template(template_path))

    logger.debug("Copying #{name} file to its proper location...")
    FileUtils.cp(tmp.path, output)

    logger.debug("Cleaning temporary #{name} file...")
    tmp.close(true)
  end

  def write_to_tmp(tmp, data)
    tmp.write(data)
    tmp.flush
  end

  # Actual filling of .erb fils with given info.
  #
  # @param template [String] path to template file.
  def populate_template(template)
    logger.debug("Populating template '#{template}'")
    erb = ERB.new(File.read(template), nil, '-')
    erb.filename = template
    erb.result(binding)
  end
end
