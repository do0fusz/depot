class Cart < ActiveRecord::Base
	has_many :line_items, dependent: :destroy 

	def add_product(product)
		current_item = line_items.find_by(product_id: product.id)
		if current_item
			current_item.quantity += 1 
			current_item.amount = current_item.total_price
		else
			current_item = line_items.build(product_id: product.id, amount: product.price)
		end
		current_item
	end

	def remove_product(product)
		if product.quantity > 1 
			product.quantity -= 1 
			product.save! 
		else
			product.destroy 
		end
	end


	def total_price
		line_items.to_a.sum {|item| item.total_price }
	end
end
