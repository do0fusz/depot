class User < ActiveRecord::Base
	validates :name, presence: true, uniqueness: true 
  has_secure_password
  after_destroy :enshure_one_admin_remains 

  private 
  def enshure_one_admin_remains
  	if User.count.zero? 
  		raise "Can't destroy last user"
  	end
  end
end
