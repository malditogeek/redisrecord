# = Sample file
require 'lib/redisrecord'

# example.rb demo class
class User < RedisRecord::Model
  database 0
  has_many :posts
  #has_one :moderator
end

# example.rb demo class
class Post < RedisRecord::Model
  database 1
  belongs_to :user
  has_many :comments
  has_and_belongs_to_many :categories
end

# example.rb demo class
class Comment < RedisRecord::Model
  database 15
  belongs_to :post
  belongs_to :user
end

# example.rb demo class
class Category < RedisRecord::Model
  has_and_belongs_to_many :posts
end

# example.rb demo class
class Moderator < RedisRecord::Model
  database 15
  belongs_to :user
end

# Example
#p u = User.new
#p u.name = 'Mauro'
#p u.age = 25
#p u.save
#p u.whatever = {:as_many_attributes => 'as you want'}
#p u.save
#p u
#p u = User.find(1)
#p p = Post.new
#p p.title = 'New Post'
#p p.user_id = u.id
#p p.save
#p p2 = Post.new
#p p2.title = 'Another post'
#p p2.user_id = u.id
#p p2.save
#p p.user
#p p2.user
#p u.posts

# Flush DB
#r = Redis.new(:db => 15)
#r.flush_db
