
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


> if you show a cart, holding the line items, you want the cart to 'hold' the number of times each item is inserted, instead of adding each item again and again. 


So, modifying the Cart model (holding the line items) is the way to go.
Offcourse you could also figure a solution by making the line_item uniq. 
but that's a different subject.

Let's go 'mental'! 
the flow:
> well, we have to check if the line_item allready exists in the cart. 
> if so, we need to increment the count. 
> 
> if the line_item doesn't exists yet, we create it.
> eater way we should make a check and a assignment.
> 
> All right, when do you want the action to take place?
> -> On the create 
> Where should the action take place? 
> -> On the Cart model ( it holds the line_items )
> The line_items controller knows to which cart it belongs
> 


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

        #here is our ClassInstanceMethod: take note of the product<dot>id
        @line_item = @cart.add_product(product.id)
    // 

```



### Smart migrations, cool stuff.. 
A bit deeper into programming with ruby.

We need a migration that carefully checks to see if there are any duplicates in line_items in the cart. Now, pay **attention**.. this migration rocks!

```ruby 
rails g migration combine_items_in_cart
```


```ruby 
def change 
    #here is where the magic is gonna happen.
    def up
        #nothing special so far, just select all the carts.
        Cart.each.all do | cart | 
        #count the occurrences of the line_item in each cart 
        sums = cart.line_items.group(:product_id).sum(:quantity)

        #Add and remove unnecessary occurrences 
        sums.each do |product_id, quantity| 
            if quantity > 1 
            #remove
            cart.line_items.where(product_id: product_id).delete_all
            #replace
            item = cart.line_items.build(product_id: product_id)
            item.quantity = quantity 
            item.save!
            end
        end   
    end    
end
```

behold the power of nifty ruby methods!
check the line 'sums = cart.line_items.group(:product_id).sum(:quantity) '
This holds some awesome magick shortcuts wizzard power (and some!)

**group** selects the elements by the given identifier, and returns a instance
containing just those objects.
**sum** then counts the given identifier (quantity) and returns a hash with the result. 

So saying, "i want a sum, with the result of each item in a cart by the number of times each product is in that cart" can be pressed into one line.
sum = cart.items.group(:itemname).sum(:items)
cool huh?! 


### migrating the down way..

```ruby 
def down
    LineItem.where("quantity > 1").each do |line_item|
        line_item.quantity.times do 
            LineItem.create (
                 cart_id: line_item.cart_id, 
                product_id: line_item.product_id, 
                quantity: 1  ) 
            end
         # don't forget to destroy the left overs
        line_item.destroy    
    end
end
```





### Safety, errors, logs.. 
Just like sessions, rails provide logger as a system used function. 
Just like sessions, you can access logger almost anywhere.

Now, a user submits an invalid cart id, let's safely construct a way to capture the error, redirect the user, and log it!


```ruby 
Class CartsController < ApplicationController
    
    # tell the controller to rescue from ActiveRecord::RecordNotFound
    rescue_from ActiveRecord::RecordNotFound, with: :invalid_cart

    // shizzle

    private

    def invalid_cart
        logger.error "Attempt to access invalid cart #{paramd[:id]}"
        redirect_to store_url, notice: 'Invalid cart'
    end
```


### Emtying the cart
Again, we are going to use the button_to because of the action we need to do.
But, we give the button the method: :delete to overrule the standard put request. 

The html bits speak for them self, so i'll skip them.
Lets have a look at the controller:


```ruby 
def destroy
    @cart.destroy 
end
```

How can we make this more 'safe' ? 
We know the session holds the :cart_id,
and the button params holds the :cart_id to.. 
aha eureka! 
```ruby 
def destroy
    @cart.destroy if @cart.id == session[:cart_id]

    # and while we are at it, lets clear the cart session totally 
    session[:cart_id] = nil 
end
```




### Total Price features :) 
Again, some nifty ruby methods chained together to do awesome stuff.
And a good example of 'name_spacing.'

First, we'd like to have the total_price for each line_items (products * quantity) .
Second, we'd like a total_price for the sum of all line_items together. (sum of all line_items)

>meditate a moment:  Should this be a method inside the controller? or should this be inside of the model? and which one would you pick for either action?

```ruby 
# Let's start at the line_items 

# the line items model has access to product, and the price. 
# A line_item holds a reference to a product_id, so line_item.product.price should return the price, and line_item.product.quantity should give the count of the items. 

# in the line items model:
class LineItems < ActiveRecord::Base
    def total_price
        products * quantity 
    end
```

>meditate on this, why should this be enough?

#### Next
The total price for the Cart, and the good news is.. 
our LineItems model now has a method called: *total_price*.. 
Why is that good news?

```ruby 

# answer: the Cart holds several line_items,
# and each line item now has a method (from the model) for the total_price

class Cart < ActiveRecord::Base
    def total_price
        line_items.to_a.sum { |item| item.total_price }
    end
```




### PLAYTIME! 
Mission: Delete the line_item from the cart. 
Bonus: Don't delete the entire line_item, but just one item from that line item.

Now this took me a few hours, because of all the relational bindings between objects, and the mission to keep it in the Model.

Logic: Tell the controller which line_item, what product, in what cart to delete.

We already have a helper method that sets the current_cart, and the line_items controller also sets the @line_item for us. So, we are only missing the product.

```html 
<% @items. each do |item| %> 
    // blabla 
    #tell the controller what item we are handeling
    <%= button_to 'delete', line_item_path(item), method: :delete %>
```

```ruby 
# in the controller we add a set_cart to the destroy action
before_action :set_cart, only: [:create, :destroy]

## stuf/actions/etc/

# then we specify the delete action

def destroy
    # what item?
    item = LineItem.find(params[:id])  # this id was passed from the browser
    # and here was the headache ...
    @line_item = @cart.remove_product(item)
    #serious.. this call took me forever to figure out. 

end


// DONT FORGET TO update THE MODEL 
class Cart < ActiveRecord::Base 
    # stuff..

    def remove_product(product)
        # ah, a stinker! 
        if product.quantity > 1 
            product.quantity -= 1 
            product.save!
            # the save is very important.
        else
            product.destroy
        end    
    
```

### Adding Ajax

> 'Ajax (which once stood for Asynchronous JavaScript and XML but now just means “making browsers suck less”).'
>  or something awesome like JavaScript Object Notation [JSON]).

Cool, let's make browser response a bit smarter 

start by telling the views to handle not html request but ajax. 
Add the 'remote: true' parameter to the action. 

browser’s internal representation of the structure and content of the document being displayed, namely, the Document Object Model (DOM)


```javascript
    // tell the DOM what to do
    $('#cart').html("<%= escape_javascript render(@cart) %>");
```




#### a helper method for the Cart in the side bar.
Let’s write a helper method called hidden_div_if(). It takes a condition, an optional set of attributes, and a block. It wraps the output generated by the block in a <div> tag, adding the display: none style if the condition is true. Use it in the store layout like this:

This code uses the Rails standard helper, content_tag(), which can be used to wrap the output created by a block in a tag. By using the &block notation, we get Ruby to pass the block that was given to hidden_div_if() down to content_tag().


```ruby

    # in the view
        <% hidden_dif_if(@cart.line_items.empty?, id: 'cart' ) do %> 
            <%= render @cart %>

    # in the Application Helper
    module ApplicationHelper
        def hidden_div_if(condition, attributes = {}, &block)
            if condition
                attributes["style"] = "display: none"
            end
                content_tag("div", attributes, &block) end
            end
```

# BRAINDAMAGE
&block keeps pulling my leg, like every &block thing and yield thing is confusing the fuck out of me.

From the documentation of the 'content_tag':
*content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)*
'... you can also use a block in which case, you pass your options as the second parameter...'

So what happens in the above issue is the module helper assigns the passed css id: 'id="car"' to the parameters={} of the hidden_div_if method.
The if statement (duhh) executes when true (so if the @cart.line_items.empty?) and will set attributes of style to "display: none".
Now the content_tag will execute, with either the css parameters: display:none, or 'id: "cart" ', it will return a 'div' element and execute the block passed to the content_tag. In this case, the render @cart is the &block.
(a &block is just a chunk of code to be iterated in this case.)



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