# = RedisRecord
# A "virtual" Object Relational Mapper on top of Redis[http://redis.googlecode.com].
#
# This is a proof-of-concept. Allows you to create schema-less data structures and
# build relationships between them, using Redis as storage.
#
# == Main repository
# http://github.com/slacker/redisrecord/tree/master
#
# == Author
# Mauro Pompilio <hackers.are.rockstars@gmail.com>
#
# == License
# MIT
#
#
# == Example 
#
#  class User < RedisRecord
#    database 15
#    has_many :posts
#  end
#  
#  class Post < RedisRecord
#    database 15
#    belongs_to :user
#    has_many :comments
#  end
#  
#  class Comment < RedisRecord
#    database 15
#    belongs_to :post
#    belongs_to :user
#  end 
#
#  >> u = User.new
#  => #<User:0xb761c3f0 @stored_attrs=#<Set: {}>, @cached_attrs={}, @opts={}>
#  >> u.name = 'Mauro'
#  => "Mauro"
#  >> u.age = 25
#  => 25
#  >> u.save
#  => [:updated_at, :age, :name, :id, :created_at]
#  >> u.whatever = {:as_many_attributes => 'as you want'}
#  => {:as_many_attributes=>"as you want"}
#  >> u.save
#  => [:updated_at, :whatever]
#  >> u
#  => #<User:0xb761c3f0 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173522.49843", :age=>25, :name=>"Mauro", :whatever=>{:as_many_attributes=>"as you want"}, :id=>1, :created_at=>"1238173522.49808"}, @opts={}>
#  >> u = User.find(1)
#  => #<User:0xb760a2a4 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173566", :age=>"25", :name=>"Mauro", :whatever=>"as_many_attributesas you want", :id=>"1", :created_at=>"1238173522.49808"}, @opts={:stored=>true}>
#  >> p = Post.new
#  => #<Post:0xb7608210 @stored_attrs=#<Set: {}>, @cached_attrs={:user_id=>nil}, @opts={}>
#  >> p.title = 'New Post'
#  => "New Post"
#  >> p.user_id = u.id
#  => "1"
#  >> p.save
#  => [:updated_at, :title, :id, :user_id, :created_at:
#  >> p2 = Post.new
#  => #<Post:0xb75e5ad0 @stored_attrs=#<Set: {}>, @cached_attrs={:user_id=>nil}, @opts={}>
#  >> p2.title = 'Another post'
#  => "Another post"
#  >> p2.user_id = u.id
#  => "1"
#  >> p2.save
#  => [:updated_at, :title, :id, :user_id, :created_at]
#  >> p.user
#  => #<User:0xb75ce754 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173566", :age=>"25", :name=>"Mauro", :whatever=>"as_many_attributesas you want", :id=>"1", :created_at=>"1238173522.49808"}, @opts={:stored=>true}>
#  >> p2.user
#  => #<User:0xb75c8480 @stored_attrs=#<Set: {:updated_at, :age, :name, :whatever, :id, :created_at}>, @cached_attrs={:updated_at=>"1238173566", :age=>"25", :name=>"Mauro", :whatever=>"as_many_attributesas you want", :id=>"1", :created_at=>"1238173522.49808"}, @opts={:stored=>true}>
#  >> u.posts
#  => [#<Post:0xb75c20a8 @stored_attrs=#<Set: {:updated_at, :title, :id, :user_id, :created_at}>, @cached_attrs={:updated_at=>"1238173641", :title=>"New Post", :id=>"1", :user_id=>"1", :created_at=>"1238173641.17936"}, @opts={:stored=>true}>, #<Post:0xb75bdb0c @stored_attrs=#<Set: {:updated_at, :title, :id, :user_id, :created_at}>, @cached_attrs={:updated_at=>"1238173858", :title=>"Another post", :id=>"2", :user_id=>"1", :created_at=>"1238173858.82325"}, @opts={:stored=>true}>]
#

require 'rubygems'
require 'activesupport'
require 'redis'

# = RedisRecord
module RedisRecord

  # Not found exception.
  class RecordNotFound < Exception; end

  # Duplicate attribute exception.
  class DuplicateAttribute < Exception; end
 
  # Connection to Redis.
  class RedisConnection < Redis; end

  # Base class.
  class Base
    attr_reader :attrs, :stored_attrs

    # Redis connection
    @@redis = RedisConnection.new#(:debug => true)
    
    # Reflections
    @@reflections = {}
 
    # Class methods 
    class << self

      # Generates reflections skeleton when the RedisRecord is inherited.
      def inherited(klass)
        @@reflections[klass.name.to_sym] = {}
        [:belongs_to, :has_many, :has_and_belongs_to_many].each do |r|
          @@reflections[klass.name.to_sym][r] = []
        end
      end

      # Retrieve records. Allowed: 
      #  * :all
      #  * :first
      #  * :last
      #  * one or more IDs.
      # 
      # Example: 
      #  Post.find(:last)
      #  Post.find(1)
      #  Post.find([1,2,3])
      #
      # Allowed options:
      #  * :should_raise: If *true* raise RecordNotFound exception on missing records. Defauls is *false*.
      def find(*args)
        options = args.last.is_a?(Hash) ? args.pop : {} 
        records = []
        case args.first
          when :all
            find_all(options)
          when :first
            find_first(options)
          when :last
            find_last(options)
          else
            find_from_ids(args, options)
        end
      end

      # Sort class objects by the given attribute. Defaults are: 
      #  * :order => 'ALPHA DESC'
      #  * :limit => 10
      #
      # Example:
      #  Post.sort_by(:updated_at) #=> Last 10 updated posts
      #  Post.sort_by(:id, :order => 'ALPHA ASC', :limit => 5) #=> First 5 posts
      def sort_by(attribute, options={})
        limit  = options[:limit]  || 10
        offset = options[:offset] || 0
        order  = options[:order]  || 'ALPHA DESC'
        ids = @@redis.sort("#{name}:list", 
                           :by => "#{name}:*:#{attribute}", 
                           :limit => [offset, limit],
                           :order => order,
                           :get => "#{name}:*:id")
        find_from_ids(ids, options)
      end

      private # class methods

      def find_all(options)
        all_ids = @@redis.list_range("#{name}:list", 0, -1)
        find_from_ids(all_ids, options)
      end

      def find_first(options)
        first_id = @@redis.list_index("#{name}:list", 0)
        find_from_ids(first_id, options)
      end

      def find_last(options)
        first_id = @@redis.list_index("#{name}:list", -1)
        find_from_ids(first_id, options)
      end

      def find_from_ids(ids, options={})
        records = []
        [ids].flatten.each do |id|
          begin
            redis_attrs = @@redis.set_members("#{name}:#{id}:attrs").to_a
            stored_attrs = @@redis.mget(redis_attrs.map {|a| "#{name}:#{id}:#{a}"})
            object_attrs = {}
            redis_attrs.each_with_index {|a,i| object_attrs[a.to_sym] = stored_attrs[i]}
            records << instantiate(object_attrs)
          rescue RedisError
            raise RecordNotFound if options[:should_raise]
            #records << nil
          end
        end
        (records.length == 1 ? records[0] : records)
      end

      # Select which database to be used.
      #  class Post < RedisRecord
      #    database 15
      #  end
      def database(db)
        @@redis.select_db db
      end

      # Returns a new object with the given attributes hash.
      def instantiate(instance_attrs={})
        new(instance_attrs, :stored => true)
      end

      # Belongs_to relationship initialization.
      #  class Post < RedisRecord
      #    belongs_to :user
      #  end
      def belongs_to(klass)
        @@reflections[self.name.to_sym][:belongs_to] << klass
        fkey = klass.to_s.foreign_key.to_sym
        define_method(klass) {
          k = klass.to_s.classify.constantize
          k.find(@cached_attrs[fkey])
        }
      end

      # Has_many relationship initialization.
      #  class Post < RedisRecord
      #    has_many :comments
      #  end
      def has_many(klass)
        @@reflections[self.name.to_sym][:has_many] << klass
        define_method("#{klass}") {
          k = klass.to_s.classify.constantize
          ids = @@redis.set_members("#{self.class.name}:#{@cached_attrs[:id]}:#{klass.to_s.singularize}_ids").to_a
          k.find(ids)
        }
      end
     
      # Has_and_belongs_to_many relationship initialization.
      def has_and_belogns_to_many(klass)
        has_many klass
        belongs_to klass.to_s.foreign_key.to_sym
      end

    end # Class methods
    
    # Instantiate a new object with the given *attrs* hash.
    def initialize(attrs={},opts={})
      @opts = opts.freeze
      @cached_attrs, @stored_attrs = {}, Set.new
      add_attributes attrs
      attrs.keys.each {|k| @stored_attrs << k.to_sym} if @opts[:stored]
      add_reflections_attributes
    end

    # Save the (non-stored) object attributes to Redis.
    def save
      # Autoincremental ID unless specified
      unless @cached_attrs.include?(:id)
        add_attribute :id, @@redis.incr("#{self.class.name}:autoincrement")
        add_attribute :created_at, Time.now.to_f.to_s
        add_attribute :updated_at, Time.now.to_f.to_s
        @@redis.push_tail("#{self.class.name}:list", @cached_attrs[:id]) # List of all the class objects
      end

      # Store each @cached_attrs
      stored = Set.new
      (@cached_attrs.keys - @stored_attrs.to_a).each do |k|
          stored << k 
          @stored_attrs << k
          @@redis.set_add "#{self.class.name}:#{id}:attrs", k.to_s
          @@redis["#{self.class.name}:#{@cached_attrs[:id]}:#{k}"] = @cached_attrs[k]
      end

      # updated_at
      @@redis["#{self.class.name}:#{@cached_attrs[:id]}:updated_at"] = Time.now.to_f.to_s
      stored << :updated_at 

      # Relationships
      @@reflections[self.class.name.to_sym][:belongs_to].each do |klass|
        @@redis.set_add("#{klass.to_s.camelize}:#{@cached_attrs[klass.to_s.foreign_key.to_sym]}:#{self.class.name.underscore}_ids", @cached_attrs[:id])
      end

      return stored.to_a
    end

    def destroy
      @@redis.list_rm("#{self.class.name}:list", 0, @cached_attrs[:id])
      @cached_attrs.keys.each do |k|
        @@redis.delete("#{self.class.name}:#{@cached_attrs[:id]}:#{k}")
      end
      @@redis.delete("#{self.class.name}:#{id}:attrs")
    end

    # Returns *true* if there are unsaved attributes.
    #  p = Post.new(:title => 'Lorem ipsum')
    #  p.save
    #  p.dirty? # => false
    #  p.body = 'Dolor sit amet'
    #  p.dirty? # => true
    def dirty?
      (@cached_attrs.keys - @stored_attrs.to_a).empty? ? false : true
    end

    # Returns *true* if the object wasn't stored before
    def new_record?
      @opts[:stored] == true ? false : true
    end

    # Current instance attributes
    def attrs
      @cached_attrs.keys
    end

    private

    # Captures the missing methos and converts it into instance attributes.
    def method_missing(*args)
      method = args[0].to_s
      case args.length
        when 2
          k, v = method.delete('=').to_sym, args[1]
          add_attribute k, v
      end
    end

    # Add attributes to the instance cache and define the accessor methods
    def add_attributes(hash)
      hash.each_pair do |k,v|
        k = k.to_sym
        #raise DuplicateAttribute unless (k == :id or !self.respond_to?(k))
        if k == :id or !self.respond_to?(k)
          @cached_attrs[k] = v
          meta = class << self; self; end
          meta.send(:define_method, k) { @cached_attrs[k] }
          meta.send(:define_method, "#{k}=") { |new_value| @cached_attrs[k] = new_value; @stored_attrs.delete(k) }
        end
      end
      hash
    end

    # Wraper around add_attributes
    def add_attribute(key, value=nil)
      add_attributes({key => value})
    end
 
    # Add the foreign key for the belongs_to relationships
    def add_reflections_attributes
      @@reflections[self.class.name.to_sym][:belongs_to].each do |klass|
        add_attribute klass.to_s.foreign_key.to_sym
      end
      #@@reflections[self.class.name.to_sym][:has_many].each do |klass|
      #  add_attribute "#{klass.to_s.singularize}_ids".to_sym, @@redis.set_members("#{self.class.name}:#{@cached_attrs[:id]}:#{klass.to_s.singularize}_ids").to_a
      #end
    end
  end

end
