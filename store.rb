require 'builder'
require 'active_record'

ActiveRecord::Base.establish_connection(
		adapter: 'sqlite3',
		database: '/db/development/sqlite3')

class Product < ActiveRecord::Base
end

class StoreApp
	def call(env)
		x = Builder::XmlMarkup.new :indent=>2
		x.declare! :DOCTYPE, :html 
		x.html do 
			x.head do 
				x.title 'Store shell '
			end
			x.body do 
				x.h1 'Store shell'
				Product.all do |product|
					x.h2 product.title 
					x << "  #{product.description} \n"
					x.p product.price 
				end
			end
		end
		response = Rack::Response.new(x.target!)
		response['Content-type'] = 'text/html'
		response.finish
	end
end
