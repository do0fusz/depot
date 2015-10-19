class CombineItemsInCart < ActiveRecord::Migration
	def change
		def up
			Cart.all.each do |cart| 
				#count the items 
				sum = cart.line_items.group(:product_id).sum(:quantity)

				sum.each do |product_id, quantity| 
					#delete all items where that product_id is mentiond
					cart.line_items.where(product_id: product_id).delete_all 

					# insert individual line items 
					item = cart.line_items.build(product_id: product_id)
					item.quantity = quantity 
					item.save!

				end
			end
		end

		def down 
			LineItem.where("quantity > 1").each do |line_item| 
				line_item.quantity.times do 
					LineItem.create(
						cart_id: line_item.cart_id, 
						line_item: line_item.product_id,
						quantity: 1)
				end
			end
		end

	end
end
