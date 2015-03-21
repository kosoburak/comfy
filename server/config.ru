require 'sinatra'
set :public_folder, "#{ENV['comfy_server_public']}"
run Sinatra::Application