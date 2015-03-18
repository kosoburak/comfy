require 'comfy_templater'
require 'settings'
require 'fileutils'
require 'webrick'
require 'mixlib/shellout'

class ComfyCreator
  
  def initialize(options, log)
    @options = options
    @log = log
    clean_output_dir
  end

  def create
    @log.debug('Prepariong for images creation...')
    templater = ComfyTemplater.new(@options, @log)
    templater.create_output
    @log.debug('Creating server for installation data...')
    @serv_dir = templater.instance_variable_get(:@temp_dir)
    @log.debug("Server will mount '#{@serv_dir}' .")
    
    #server = Mixlib::ShellOut.new("ruby -r webrick -e 'WEBrick::HTTPServer.new(:Port=>1234,:DocumentRoot=>\"#{@serv_dir}\").start'")
    #server.run_command
    # If all went well, the results are on +stdout+
    #puts server.stdout
    # # find(1) prints diagnostic info to STDERR:
    #puts "error messages" + server.stderr
    # # Raise an exception if it didn't exit with 0
    #server.error!
    
    for distribution in @options.distros
      @log.debug("Calling packer - Creating distro: '#{distribution}'.")

      @packer = Mixlib::ShellOut.new("packer build '#{@serv_dir}'/'#{distribution}'.json")
      @packer.live_stdout
      @packer.run_command
      # If all went well, the results are on +stdout+
      puts @packer.stdout
      # find(1) prints diagnostic info to STDERR:
      puts "error messages" + @packer.stderr
      # Raise an exception if it didn't exit with 0
      @packer.error!

    end
    
    @log.debug('Packer finished.')

    #@server.stop
    #@log.debug('Server stopped.')
    delete_temp_dir(@serv_dir)

  end

  def delete_temp_dir(dir)
    FileUtils.remove_entry_secure dir
  end    

  def clean_output_dir
    output_dir = Dir.new(Settings.output['output_dir'])
    output_dir.entries.each do |entry|
      File.delete("#{Settings.output['output_dir']}/#{entry}") if /[0-9]{14}/ =~ entry
    end
  end

end

