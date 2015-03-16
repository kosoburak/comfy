require 'settings'
require 'logger'
require 'tempfile'
require 'erb'
require 'fileutils'


class ComfyTemplater

  attr_reader :data 

  def initialize(options, log = Logger.new(STDOUT))
    
    data = {}
    data[:size] = options.size
    data[:format] = options.format

    @distros = options.distros
    @output = "#{Settings.output['output_dir']}/"
    @log = log

  end


  def create_output

    @log.debug('Creating temporary files...')
    temp = Tempfile.new('temp')
    #temp2 = Tempfile.new('temp2')
    @log.debug("Temporary files '#{temp.path}' and were created.")

    for distribution in @distros
      @log.debug("Creating files for distribution '#{distribution}'...")
      @output << "#{distribution}"
      @template = "#{File.dirname(__FILE__)}/lib/templates/#{distribution}/#{distribution}.erb"
      @log.debug('Generating password...')
      data[:password] = ComfyTemplater.pswd_generator
      @log.debug('Writing to temporary file...')
      write_to_temp(temp, edit_template)
      cp_output(temp.path, @output)
      @log.debug('Cleaning temporary file...')
      temp.truncate(temp, 0)
    end

  ensure
    tmp.close(true)
  end

  def cp_output(temp, to)

    @log.debug('Copying temporary file into regular output...')
    FileUtils.cp(temp, to)

  end

  def write_to_temp(temp, data)

    tmp.write(data)
    tmp.flush

  end

  def pswd_generator
    
    @log.debug('Generating a random password')
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    password = (0...20).map { o[rand(o.length)] }.join
    return @password

  end

  def edit_template
    
    @log.debug('Template editing')
    erb = ERB.new(File.read(@template), nil, '-')
    erb.filename = @template
    erb.result(binding)

  end

end
