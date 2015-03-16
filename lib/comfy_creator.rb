require 'comfy_templator'
require 'settings'

class ComfyCreator
  
  def initialize(options, log)
    @options = options
    @log = log
  end

  def create
    @log.debug('Prepariong for images creation...')
    templater = ComfyTemplater.new(@options, @log)
    templater.create_output

  end

end
