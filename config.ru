$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'sinatra'

set :environment, :production

require 'subnet'

run Sinatra::Application
