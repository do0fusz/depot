module StoreHelper
	def count_access
		session[:counter] ||= 0
		session[:counter] += 1 
	end
end
