
# personal notes on the Agile web 4 book.


You can use the following SFTP credentials to upload your files (using FileZilla/WinSCP/Rsync):
178.62.178.217
  * Host: 178.62.178.217
  * User: rails
  * Pass: 12uGtdqp4e

You can use the following Postgres database credentials:
  * User: rails
  * Pass: HgdY9vDBVy


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

    #testing AJAX calls
    test "should create upon ajax call" do 
        assert_difference(LineItems.count) do 
            xhr :post, :create, product_id: products(:ruby).id 
        end
        assert_repsonse success: 
        assert_select_jquery :html, '#cart' do 
            assert_select 'tr#current_item td', \/My Awesome Book title\/
        end
    end

    #testing the orders, the helper method, 
    test "Carts should not be empty " do 
        get :new
        assert_redirect_to store_url, notice: "hahah"
    end

    test "Should get a cart if it has items" do 
        item = LineItem.new
        item.build_cart 
        item.product = products(:ruby)
        item.save
        session[:cart_id] = item.cart.id 
        get :new 
        assert_response :success
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



### Coffeescript 

For the Clickable image, we are conna use a nice coffescript hack, check it out.

```javascript
    
    // In assets/javascript/store.coffee, change it to store.js.coffee

    $(document).on "ready page:change", ->
        $('.store .entry >img').click ->
        $(this).parant().find(':submit').click()
```

That's it! It turns the entire image into a clickable link with a simple javascript (coffee script) action!


And testing Javascript is just as easy:

```ruby 
test "should update with ajax" do 
    assert_difference(LineItems.count) do 
        xhr :post, :create, product_id: products(:ruby).id
    end
    
    assert_response :success
    assert_select_jquery :html, '#cart' do 
        assert_select 'tr#current_item td', /my awesome book title/ 
    end
    # xhr :post vs. simply post, where xhr stands for the XML- HttpRequest mouthful
```



### The Order model
for obvious reasons i skipped the stuff already known to mankind and apes.
A neat trick i saw,

```ruby
#in a form for helper, the call is direct on the Order model, Constant of PAYMENT_type, and the prompt: places a dumy in the field.. great stuff. -->
    <% f.select :pay_type, Order::PAYMENT_TYPE, prompt: "select a payment type"
```



associations:
Order has many line_items, that's it.
you create a new order, 
and update it with the items from the cart (remember current_cart?)
controller actions ->
    @order = Order. new
    @order.add_line_items_from_cart(@cart)

```ruby 
class OrdersController < ApplicationController
    before_action :set_cart

    def create 
        @order = Order.new 
        @order.add_line_items_from_cart(@cart)

        if @order.save
            # don't forget to destroy the CART!
            # no need to have it around ;)
            Cart.destroy(session[:cart_id])
            session[:cart_id] = nil 
```


Now the magic is going to happen in the model of the order, since you made m method call 'add_line.......' 


```ruby 
class Order < ActiveRecord::Base
    has_many :line_items 
    def add_line_items_from_cart(cart)
        cart.line_items.each do |item| 
            # set the cart item to nil, otherwise it will 
            # be destroyed when the cart is destroyed! 
            item.cart_id = nil 
            line_item << item 
        end
    end
    # that's it! An Order holds line_items,from the @cart
```




A product doesn't have any orders yet, we could make an entirely new model for that but since there is already a model for holding orders that doesn't make sense.

```ruby 
class Product < ActiveRecord::Base
    has_many :line_items 
    has_many :orders, trough: :line_items

```


Member routes
This will perform the who bought action on the member of products. 

```ruby
resources :products do 
    get 'who_bought', on: :member
end


THIS is actually very usefull, 

resources :products do 
    get 'on_sale', on: :products
    get 'not_available', on: :products
    get ''
```







### H-Sending Email.
3 steps: 
    Configure How, 
    When 
    What. 
That easy 

Generate a Mailer and actions, make the Call from the controller 
`Mailer.Action('variables').deliver `
:smtp -> Human configurable smtp mailer, like gmail. 
:sendmail -> System used sendmail /usr/bin, needs -i -t options.
:test -> won't sent an actual email, array to be accessed through ActionMailer::Base.deliveries


You can set up the configuration mailer for each environment, or use the global environment.rb 

```ruby 
Rails.application.initialize! 

AppName.configure do 
    config.action_mailer.delivery_method = smtp 
    config.action_mailer.smtp_settings={
        address: "smtp.gmail.com",
        port: 587,
        domain: "localhost:3000", 
        authentication: "plain",
        user_name: "name-something", 
        password: "password somehting", 
        enable_starttls_auto: true
    }
```

You can run a generator to create a mail action / model / views/ 
rails g mailer OrderNotifier received shipped 

The OrderNotifier will have the actions received and shiped, you can pass them variables through the create action, like so:

```ruby 
class OrdersController <ApplicationController
    //
    def create
    //
        if @order.save
            //
            OrderNotifier.received(@order).deliver 


## mailer

    def received(order)
    # give the views their variable
    @order = order            
    mail to: order.email, subject: "Hi mail"


```



### i - Loggin n, and adding users. 
Most if this i already know from the hartl tutorial. 

```ruby 
    
    class ApplicationController < ApplicationController::Base 

    before_action :authorize 

    protected 

    def authorize 
        unless User.find_by(user_id: params[:user_id])
        redirect_to store_url, notice: "do this"
```
_
##### candy: 
making a scope on the model:
```ruby
    scope :beer, ->{ where(availeble: true) }
    scope :unavailable, ->{ where(available: [nil, false,])}
```



### Enshure one admin remains.

set a hook (before/after) action. 
define it, raise error, edit controller

```ruby 

    class User < ActiveRecord::Base 
    after_destroy :enshure_one_remains 

    def enshure_one_remains
        if User.count.zero? 
            raise "One admin should remain"  <!-- raise !
        end
    end



    // controller 

    class UsersController < ApplicationController
        def destroy 
        begin
            @user.destroy
            flash[:notice] = "User #{@user.name} destroyed"
         rescue StandardError => e 
            flash[:notice] = e.message  

```


### Internationaliziation (without a gem)

Add scope to router, en nest the 'to be translated' sources in there
The parentheses mean it's optional. 

First: Create an initializer, i18n.rb in the initializer. 
Serve the default, and a array with options

```ruby 
// config/initializers/i18n.rb 

i18.default_locale = :en 
languages = [
    ['English', 'en'],
    ['Dutch', 'nl']]
```

Next, set the routes, make it optional with a pair of '()'
            ['French', 'fr']]
```ruby 
scope '(:locales)' do 
    resources :products 
    resources :titties
    resources :pages 
end

```

Then in the html, just call the translation yaml 
The translation yaml is indented by the scope it needs to search for.
Example, the views / store would be views space space store.
This also goes for number formatting, and activerecord messages. 

 activerecord:
    errors:
            messages:
            inclusion: "no est&aacute; incluido en la lista" blank: "no puede quedar en blanco"

```html 
<%= t('.item') %>
```

```yaml
en:
    application:
        title: "This title"
```

### Selecting the locale.

```html 
<div id="banner">
    <%= form_tag store_path, class: "locale" do %>
        <%= select_tag 'set_locale', 
            options_for_select(LANGUAGES, I18n.locale.to_s), 
            onchange: 'this.form.submit()' %>
        <%= submit_tag 'submit' %>
        <%= javasript_tag "$('.locale input').hide() " %> 
    <% end %>

</div>
```


Setting the index action in store_controller
```ruby 
class StoreController < ApplicationController
def index 
    if params[:set_locale] 
        redirect_to store_url(locale: params[:set_locale])
    else
        @products = Product.order(created_at: 'DESC')
    end
end
```




### Staging
Add environment to database.yml and environment file. 
### Name spacing, 
rails generate controller Admin::Book action1 action2 ...
rails generate controller User::Book action1 action2 ...

### ActiveRecord
The ORM layer for rails, object-relation-model.
Set the primary key in the model 
```ruby
class Book <ActiveRecord::Base
    self.primary_key = "ISBN"
```


#Relationships
has_one has_many belongs_to has_and_belongs_to_many 

####Has One
The model 'Invoice'  ->  belongs_to :order', 
The model 'order ->   has_one :invoice'. 
- has_one (has one to zero or one relationship) is implemented by using a foreign_key to reference at most a single row of one other table.
For example,
- the model for the table that holds the foreign key will have the belongs_to relationship. In our example the Invoice would hold foreign_key order_id. 
####Has Many
The model 'order -> has_many :line_items'
The model 'line_item -> belongs_to :order'
-Allows to represent a collection of objects
-Foreign key again is applied to the child object.
####Has and Belongs to Many
The model product -> has_and_belongs_to_many :category 
the model category -> has_and_belongs_to_many :product
-The relationship states that any model contains multiple objects of the table from the other side, and vice versa.
-Naming: Joint_table naming is alphabetical, example: Order.categorys_products



### Create new Rows (objects)
```ruby 

# Create new Rows(objects) with a variable (new_object)
new_object = Order.new
new_object.name = "Object name"
new_object.price = 23
new_object.save 

# Create new Rows(objects) with a bloc 
Order.new do |o|
    o.name = "object name"
    o.price = 23 
    o.save
end

# Create new objects from a hash, good for interacting with the view :) 
# create() will initiate and save() the object.
new_object = Object.create(
        name: "Object name",
        price: 23 )
# create new Rows(objects) from an array of hashes.
new_object = Object.create(
    [ {name: "Object name", price: 23}, 
      {name: "second object", price: 24 } ])

```


## Quering SQL 
```ruby  
    # insert question marks as template holders. 
    name = params[:name]
    type = params[:pay_type]
    pos = Orders.where("name = :name and pay_type = :type", name: name, type: type)

    pos = Orders.where("name = :name and pay_type = :pay_type", params[:order])


    class Order < ActiveRecord::Base 

    def Order.find_on_page(page_num, page_size)
        order(:id).limit(page_size).offset(page_num * page_size)

    scope last_n_days, lambda { |days| where('updated_at > ?', days) }    
    scope checks, -> { where(payment_type: :check) }
    # Order.last_n_days(45) -> Orders from the last 45 days
    # Order.checks.last_n_days(5) -> Order with paytype check of last 5 days.

    # Order.find by sql by sql 
    order = Order.find_by_sql("select name, pay_type, from orders")
    first = orders[0]
    first.attributes
    first.attribute_names
    first.attribute_present?("beer")
```

```ruby

class Account <ActiveRecord::Base 
    validates :balance, numbericality: {greater_than_or_equal_to: 0 }
    def withdraw(amount)
        adjust_balance_and_save!(-amount)
    end
    def deposit(amount)
        adjust_balance_and_save!(amount)
    end
    private
    def adjust_balance_and_save!(amount)
        self.balance += amount 
        save! # <!-- use the save! to raise error on exception. 
    end
end

# The 'transaction' method will save to the database unless a exception is raised within the block. 
begin
    Account.transaction do # transaction is a sql method that 
    user.deposit(259)
    user.withdraw(390)
    end
rescue 
    puts "Transfor aborted"
end

```


###Action Dispatch and Action Controller
ActionDispatch routes requests to controller
ActionController converts requests into responses 
ActivonView is used by the action controller to format the responses.

```ruby
routes are awesome

resources products do
    resources reviews
    end
end

# now you'll have a resources_reciews_path' that points to 
# /products/:product_id/reviews/:id 

# concern will produce a reusable block
concern :revieweble do
    resources :reviews
end
resources :products, concern: :reviewable 
resources :users, concern: :reviewable 

# shallow resources makes url smaller
resources :products, shallow: true do
    resources :reviews
end
```



#Render Redirect 

```ruby 
render(text: "hello")
render(action: :name)
render(template: "/controller/action", [locals: hash])
render(partial: :name)
render(xml: stuff)
render(json: stuff, [callback: hash])
render(:update) do |page| #RJS block.

send_data(data,options)  # Or send_file
    def sales_graph
        png_data = Sales.plot_for(Date.today.month)
        send_data(png_data, type: "img/png", disposition: "inline")
    end

redirect_to(action: 'parent_action') <-- WRONG bad practice, see foot note.
redirect_to(actions: ... , options: ... )
redirect_to(path)
redirect_to(:back)
# wrong! 301 - 307 
#Dont use redirect_to Upon child of a parent, when the create using a redirect, this will leave the browser thinking there will still be a response on the get request. 




# VIEWS
#
 #You can attach images to forms, by using multipart: true 
<%= form_for(:picture, url: {action: 'save'}, 
                      html: {multipart: true}) do |form| %>
  "upload Picture" <%= form.file_field("upload picutre") %>
<% end %>                                                               %>

```



### Layout per controller
```ruby 
# This will give the controller a seperate layout per deterimination. 
class BooksController < ApplicationController
    layout :determine_layout

    private
    def deterimine_layout
        if Store.is_closed?
            "store_down"
        else
            "standard"
        end
    end
end
```



```ruby 
# This will iterate over the collection. 
<%= render( partial: 'animal',
            collection: %w{ant bee cat dog elk},) 

# This wil render a shared partial and provide a local. 
<%= render("shared/header", locals: {title: @article.title })            

# This will also render shared statement
<%= render(partial: "shared/post", object: @article )

# partial with layouts
<%= render partial: "user", layout: "administrator"

# partial with layout block
<%= render layout: "administrator" do 
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