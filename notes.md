
# personal notes on the Agile web 4 book.

### TESTING references.

```ruby
require 'test_helper'
class TheControllerTest < ActionController::TestCase
    test "should get index page " do 
        get :index 
        assert_response :success
        assert_select '#main #jumbotron', minimum: 1
    end     

    #controller test
    test "should create line_item" do 
        assert_difference('LineItem.count') do 
            post :create, product_id: products(:ruby).id 
        end
        assert_redirected_to cart_path(assigns(:line_item).cart)
    end
end
```

assert_select() performs varies based on the type of parameter.
- numbers -> quantity
- string -> result 
- regex -> result 


### CACHING of partials, 
to handle caching of partials you set the action_controller.perform_caching in the environment to true (development.rb)

On the model you create method for self (think about it) to sort and order the products

```ruby 
# in the model
class Product < ActiveRecord::Base
    // validations 
    def self.latest 
     Product.order(:updated_at).ast 
    end
end
```

```html
<!-- in the view
 add caching for the elements you want to be cached 
 there you call the cache method and pass it an array of the elements you want to cache, the naming of ['you decide', Thing.to_cache ].-->

<% cache ['store', Product.latest ] do %>
    <% @products.each do |product| %>
        <% cache ['entry', product] do %>
            <div class="entry">
```



###  Chapter 9, Task D:Cart Creation
Rails makes the current session look like a hash[:hash] to the controller, so we'll store the ID of the cart in the session by indexing it with the symbol for the :cart_id. That way the session will hold a :cart_id

- you do this by making a module with a private method 
- the method is only available for the controller self. 
rails will NEVER make it available for a action to the controller
- it is placed inside the 'concerns' folder of the 'controllers' folder.
- it will be a module
- it extends ActiveSupport::Concern
- will have a ActiveRecord::RecordNotFound rescue 

```ruby 
module CurrentCart
extend ActiveSupport::Concern
    private
    def set_cart
        @cart = Cart.find(session[:cart_id])
        rescue ActiveRecord::RecordNotFound
        @cart = Cart.create 
        session[:cart_id] = @cart.id 
    end
end
```


### Linking Line Items to the CART
besides the normal active record associations we create a so called hook. 
`'A hook is an action performed on the object at a certain moment'`

The hook is important to check and see if the line item is empty.
since you're working on the model of the object itself, you don't have to refer to what instance you're communicating the method to. 

```ruby 
class Product
// associations/validations 
before_destroy :check_if_empty

private
def check_if_empty
    if line_items.empty? 
        return true 
    else
        errors.add(:base, "line items present")    
        return false 
    end
end
```

##### Creating the Line item

`link_to` uses a 'get' request
`button_to` method will correspond to the 'post request/action' : `create`. 

We are going to use the **Module** we created earlier to set the Cart_id.
after that, update the 'create' action.

```ruby 
class LineItemsController< ApplicationController 
    //
    include CurrentCart  #the earlier created CurrentCart Module. 
    before_action :set_cart, only: [:create] # the method for setting the cart

    //
    def create
        product = Product.find(params[:product_id])
        @line_item = @cart.line_items.build(product: product)
    # the button was set to serve the product in the params. because the cart is set, you can now make a line item trough the carts associations. so, since a cart has a line item and a line item belongs to a cart, and to a product. 
    # The BUILD method will build the object @line_item through the cart item and the product
```

Params are important in rails, they hold the parameters handled between browser requests and controllers. 
In this case we store the corresponding Product.find('item') from the :product_id out of the params in a variable product.
Then we pass the product to the @cart.line_items.build. to create the relation between the @cart object and the product object. 

### Task E: Chapter 10.1, Creating a smarter Cart 
The cart is supposed to count the number of items from the same product, en just increment the number of times the item is added to the cart instead of adding complete new line to the db with the same field.. sounds legit!



```ruby 
#first create the migration 

rails g migration add_quantity_to_line_items quantity:intger
# open the migration file and add a default value of ->  default: 1


```


Meditation time, which controller should be modified, and which model? 
The action you want to perform: 
*IF a user adds a item to his cart, the line item should not be duplicated *
Now if you read between the lines, matter of speaking, what holds the line_items? which controller model holds those items and adds/deletes them? 
you're right

> The cart holds the line_items, 
> meditate on this one:

```ruby 

#Model: Cart.rb

class Cart < ActiveRecord::Base
    #add a line_item to the cart
    def add_product(product_id)
        #find the given line_item
        current_item = line_item.find_by(product_id: product_id)
        #if it exists
        if current_item 
            #increment the quantity
            current_item.quantity += 1 
        else
            #if it doesn't exist, make it!
            current_item = line_item.build(product_id: product_id)
        end
        #oh, and return it tot the controller.
        current_item
    end
```


```ruby 

#controller LineItems
class LineItemsController < ApplicationController
    // shhizzle 

    def create
        product = Product.find(params[:product_id])
        @line_item = @cart.add_product(product)
    // 

```




```ruby 
def beer(drinks)
    puts "hi beer"
end
```


[ ]stuff to do 
`strike through use the ~`
#h1 
##h2 
###h3
[linkg](http://dothis/"link")

> 'block >'