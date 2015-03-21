module Comfy
  GEM_DIR = File.realdirpath("#{File.dirname(__FILE__)}/..")
  require 'comfy/version'
  require 'comfy/templater'
  require 'comfy/opts'
  require 'comfy/creator'
end
