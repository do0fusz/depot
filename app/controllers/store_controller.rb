class StoreController < ApplicationController
	include StoreHelper
	include CurrentCart
	before_action :set_cart
	
  def index
  	@products = Product.order(:title)
  	@counter = count_access
  end
end
