require 'comfy_templater'
require 'settings'
require 'fileutils'

class ComfyCreator
  
  def initialize(options, log)
    @options = options
    @log = log
 #   delete_output_dir
  end

  def create
    @log.debug('Prepariong for images creation...')
    templater = ComfyTemplater.new(@options, @log)
    templater.create_output

  end

#  def delete_output_dir
#  end    

end
