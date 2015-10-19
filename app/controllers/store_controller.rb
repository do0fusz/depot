class StoreController < ApplicationController
	include StoreHelper
  def index
  	@products = Product.order(:title)
  	@counter = count_access
  end
end
