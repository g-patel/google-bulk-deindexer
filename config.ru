require 'rack'
require_relative 'deindexer_ui'
require 'tilt/erb'
require 'rack-timeout'

use Rack::Timeout
Rack::Timeout.timeout = 10800 # 3 hrs
Rack::Timeout.wait_timeout = false # disabled
Rack::Timeout.wait_overtime = false # disabled

run Sinatra::Application
