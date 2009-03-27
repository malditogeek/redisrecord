# RedisRecord
A "virtual" Object Relational Mapper on top of [Redis](http://redis.googlecode.com).

This is just a proof-of-concept. Allows you to create relationships between classes <br/>
and store them in Redis, a key-value storage. Totally schema-less.

## Author
Mauro Pompilio <hackers.are.rockstars@gmail.com>

## License
MIT


## Example
		
		class User < RedisRecord::Base
		  database 15
		  has_many :posts
		end
		
		class Post < RedisRecord::Base
		  database 15
		  belongs_to :user
		  has_many :comments
		end
		
		class Comment < RedisRecord::Base
		  database 15
		  belongs_to :post
		  belongs_to :user
		end 
		
		>> u = User.new
		=> #<User:0xb761c3f0 @stored_attrs=#<Set: {}>, @cached_attrs={}, @opts={}>
		>> u.name = 'Mauro'
		=> "Mauro"
		>> u.age = 25
		=> 25
		>> u.save
		=> [:updated_at, :age, :name, :id, :created_at]
		>> u.whatever = {:as_many_attributes => 'as you want'}
		=> {:as_many_attributes=>"as you want"}
		>> u.save
		=> [:updated_at, :whatever]
		>> u
		=> #<User:0xb761c3f0 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173522.49843", :age=>25, :name=>"Mauro", :whatever=>{:as_many_attributes=>"as you want"}, :id=>1, :created_at=>"1238173522.49808"}, @opts={}>
		>> u = User.find(1)
		=> #<User:0xb760a2a4 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173566", :age=>"25", :name=>"Mauro", :whatever=>"as_many_attributesas you want", :id=>"1", :created_at=>"1238173522.49808"}, @opts={:stored=>true}>
		>> p = Post.new
		=> #<Post:0xb7608210 @stored_attrs=#<Set: {}>, @cached_attrs={:user_id=>nil}, @opts={}>
		>> p.title = 'New Post'
		=> "New Post"
		>> p.user_id = u.id
		=> "1"
		>> p.save
		=> [:updated_at, :title, :id, :user_id, :created_at:
		>> p2 = Post.new
		=> #<Post:0xb75e5ad0 @stored_attrs=#<Set: {}>, @cached_attrs={:user_id=>nil}, @opts={}>
		>> p2.title = 'Another post'
		=> "Another post"
		>> p2.user_id = u.id
		=> "1"
		>> p2.save
		=> [:updated_at, :title, :id, :user_id, :created_at]
		>> p.user
		=> #<User:0xb75ce754 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173566", :age=>"25", :name=>"Mauro", :whatever=>"as_many_attributesas you want", :id=>"1", :created_at=>"1238173522.49808"}, @opts={:stored=>true}>
		>> p2.user
		=> #<User:0xb75c8480 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173566", :age=>"25", :name=>"Mauro", :whatever=>"as_many_attributesas you want", :id=>"1", :created_at=>"1238173522.49808"}, @opts={:stored=>true}>
		>> u.posts
		=> [#<Post:0xb75c20a8 @stored_attrs=#<Set: {:updated_at, :title, :id, :user_id, :created_at}>, @cached_attrs={:updated_at=>"1238173641", :title=>"New Post", :id=>"1", :user_id=>"1", :created_at=>"1238173641.17936"}, @opts={:stored=>true}>, #<Post:0xb75bdb0c @stored_attrs=#<Set: {:updated_at, :title, :id, :user_id, :created_at}>, @cached_attrs={:updated_at=>"1238173858", :title=>"Another post", :id=>"2", :user_id=>"1", :created_at=>"1238173858.82325"}, @opts={:stored=>true}>]
