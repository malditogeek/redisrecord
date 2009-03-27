require 'rubygems'
$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'redisrecord'

# Spec helper
class Customer < RedisRecord::Base
  database 15
end

# Spec helper
class User < RedisRecord::Base
  database 15
  has_many :posts
  has_many :comments
end

# Spec helper
class Post < RedisRecord::Base
  database 15
  belongs_to :user
  has_many :comments
end

# Spec helper
class Comment < RedisRecord::Base
  database 15
  belongs_to :post
  belongs_to :user
end

