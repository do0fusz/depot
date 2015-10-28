require 'rubygems'
require 'bundler/setup'

require './store'

use Rack::ShowExceptions

map '/store' do 
	run StoreApp.new
end
