require 'settings'
require 'logger'
require 'tempfile'
require 'erb'
require 'fileutils'
require 'tmpdir'


class ComfyTemplater

  attr_accessor :data 

  def initialize(options, log = Logger.new(STDOUT))
    
    @data = {}
    data[:format] = options.format
    data[:size] = options.size.to_s
    data[:password] = ""
    data[:output_dir] = Settings.output['output_dir']
    data[:scripts] = Settings.input['scripts']

    @distros = options.distros

    @temp_dir = Dir.mktmpdir() 
    @output_json = "#{@temp_dir}/"
    @output_cfg = "#{@temp_dir}/"
    @log = log

  end

  # Creates *.json and *.cfg files from templates for all distributions
  # and saves them to /tmp/
  def create_output
  
    @log.debug("DISTROS: '#{@distros}'")
    @log.debug('Creating temporary files...')
    temp = Tempfile.new('temp')
    temp2 = Tempfile.new('temp2')
    @log.debug("Temporary files '#{temp.path}' and '#{temp2.path}' were created.")

    for distribution in @distros
      @log.debug("Creating files for distribution '#{distribution}'...")
      @output_json << "#{distribution}.json"
      @output_cfg << "#{distribution}.cfg"
      @template_json = "#{File.dirname(__FILE__)}/templates/#{distribution}/#{distribution}.json.erb"
      @template_cfg = "#{File.dirname(__FILE__)}/templates/#{distribution}/#{distribution}.cfg.erb"
      @log.debug('Generating password...')
      data[:password] = pswd_generator
      @log.debug('Writing to temporary files...')
      write_to_temp(temp, edit_template(@template_json))
      write_to_temp(temp2, edit_template(@template_cfg))
      cp_output(temp.path, @output_json)
      cp_output(temp.path, @output_cfg)
      @log.debug('Cleaning temporary files...')  
      temp.truncate(0)
      temp2.truncate(0)
    end

  ensure
    temp.close(true)
    temp2.close(true)
  end

  def cp_output(temp, to)

    @log.debug('Copying temporary file into regular output...')
    FileUtils.cp(temp, to)

  end

  def write_to_temp(temp, data)

    temp.write(data)
    temp.flush

  end

  def pswd_generator
    
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    @password = (0...50).map { o[rand(o.length)] }.join

  end

  def edit_template(template)
    
    @log.debug("Template: '#{template} 'editing...")
    erb = ERB.new(File.read(template), nil, '-')
    erb.filename = template
    erb.result(binding)

  end

end
