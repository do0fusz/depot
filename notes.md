
# personal notes on the Agile web 4 book.

### TESTING page 104: chapter 8, task: c.

```ruby
require 'test_helper'
class TheControllerTest < ActionController::TestCase
    test "should get index page " do 
        get :index 
        assert_response :success
        assert_select '#main #jumbotron', minimum: 1
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

```ruby 
class LineItemsController< ApplicationController 
    //
    include CurrentCart  #the earlier created CurrentCart Module. 
    before_action :set_cart, only: [:create] # the method for setting the cart
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