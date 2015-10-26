class StoreController < ApplicationController
	skip_before_action :authorize 
	include StoreHelper
	include CurrentCart
	before_action :set_cart
	
  def index
  	@counter = count_access
  	if params[:set_locale] 
  		redirect_to store_url(locale: params[:set_locale])
  	else
	  	@products = Product.order(:title)	
  	end
  end
end
