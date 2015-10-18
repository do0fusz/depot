require 'test_helper'

class ProductTest < ActiveSupport::TestCase
	fixtures :products
	
	def new_product(image_url) 
		Product.new(title: "My book title", 
				description: "yyy", 
				price: 1, 
				image_url: image_url )
	end
  
  test "product attributes must not be empty" do 
  	product = Product.new 
  	assert product.invalid? 
  	assert product.errors[:title].any? 
  	assert product.errors[:image_url].any?
  	assert product.errors[:description].any?
  	assert product.errors[:price].any? 
  end

  test "price most be bigger then 0" do 
			product = Product.new(title: "humpty dumpty", 
  		description: "its about a bear and cookies", 
  		image_url: "zzz.jpg")
  	product.price = -1 
  	assert product.invalid? 
  	assert_equal  ["must be greater than or equal to 0.01"], product.errors[:price]

  	product.price = 0
  	assert product.invalid? 
  	assert_equal ["must be greater than or equal to 0.01"], product.errors[:price]

  	product.price = 1
  	assert product.valid? 
  	assert_equal false, product.errors.any? 
	end

	test "image url validation" do 
		good = %w{ fred.jpg fred.gif FRED.GIF FREDD.Jpg }
		bad = %w{ fred.url/more.jpb fred.doc fred.gif/more fred.gif.more }
		
		good.each do |name| 
			assert new_product(name).valid?, "#{name} should be valid"
		end

		bad.each do |name| 
			assert new_product(name).invalid?, "#{name} should not be valid"
		end
	end

	test "product name is uniqe " do 
		product = Product.new( title: products(:ruby).title,
		description: "hi", 
		price: 99.9,
		image_url: 'bob.jpb' )
		assert product.invalid? 
		assert_equal ["has already been taken"], product.errors[:title]
	end

	# test "product name is uniqe title - i18n" do 
	# 	product = Product.new( title: products(:ruby).title ,
	# 		description: "yyy",
	# 		price: 1,
	# 		image_url: 'fred.jpg' )
	# 	assert product.valid? 
	# 	assert_equal [I18n.translate('errors.messages.taken')], product.errors[:title]
	# end

end
