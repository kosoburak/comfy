$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

#require 'simplecov'
#SimpleCov.start

ENV['RAILS_ENV'] = 'test'

require 'comfy'
require 'comfy/opts'

GEM_DIR = File.realdirpath("#{File.dirname(__FILE__)}/..")

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.order = 'random'
end
