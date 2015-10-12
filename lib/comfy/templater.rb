require 'settings'
require 'logger'
require 'tempfile'
require 'erb'
require 'fileutils'
require 'tmpdir'

class Comfy::Templater
  attr_reader :logger, :data

  def initialize(data, logger)
    @data = data
    @logger = logger
  end

  # Prepares *.json and *.cfg files from templates for selected distribution
  def prepare_files
    prepare_file('cfg')
    prepare_file('packer', true)
  end

  private

  def prepare_file(name, packer = false)
    logger.debug("Creating temporary #{name} file...")
    tmp = Tempfile.new("comfy_#{name}")
    logger.debug("Temporary file '#{tmp.path}' was created.")

    output = File.join(data[:server_dir], "#{data[:distribution]}.#{name}")

    logger.debug("Writing to temporary #{name} file...")
    template_path = File.join(data[:template_dir], data[:distribution], "#{data[:distribution]}.#{name}.erb")
    template_path = File.join(data[:template_dir], 'packer.erb') if packer
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

  def populate_template(template)
    logger.debug("Populating template '#{template}'")
    erb = ERB.new(File.read(template), nil, '-')
    erb.filename = template
    erb.result(binding)
  end
end
