require 'lib/redisrecord'

# example.rb demo class
class User < RedisRecord::Base
  database 15
  has_many :posts
end

# example.rb demo class
class Post < RedisRecord::Base
  database 15
  belongs_to :user
  has_many :comments
end

# example.rb demo class
class Comment < RedisRecord::Base
  database 15
  belongs_to :post
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
#r = Redis.new
#r.select_db 15
#r.flush_db
