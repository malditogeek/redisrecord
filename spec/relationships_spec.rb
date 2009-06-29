require File.dirname(__FILE__) + '/spec_helper'

describe "RedisRecord" do

  before do
    # User
    @u1 = User.new(:name => 'Foo')
    @u1.save
    #puts "User1 => #{@u1.inspect}"

    # Posts
    @p1 = Post.new(:title => 'Post1', :body => 'Lorem ipsum')
    @p1.user_id = @u1.id
    @p1.save
    #puts "Post1 => #{@p1.inspect}"
    @p2 = Post.new(:title => 'Post2', :body => 'Lorem ipsum')
    @p2.user_id = @u1.id
    @p2.save
    #puts "Post2 => #{@p2.inspect}"

    # Comments
    @c1 = Comment.new(:text => 'Comment1|Post1')
    @c1.user_id = @u1.id
    @c1.post_id = @p1.id
    @c1.save
    #puts "Comment1 => #{@c1.inspect}"
    @c2 = Comment.new(:text => 'Comment2|Post1')
    @c2.user_id = @u1.id
    @c2.post_id = @p1.id
    @c2.save
    #puts "Comment2 => #{@c2.inspect}"
  end

  after do
    r = Redis.new
    #r.select_db 15
    r.flush_db
  end

  it "should find the Posts/Comments relationships through the :has_many methods of the User" do
    posts = @u1.posts
    posts.length.should == 2
    posts.each do |p|
      ['Post1','Post2'].include?(p.title).should == true
    end
    comments = @u1.comments
    comments.length.should == 2
    comments.each do |c|
      ['Comment1|Post1','Comment2|Post1'].include?(c.text).should == true
    end
  end

  it "should find the User relationship through the Post :belongs_to method" do
    @p1.user.id.should == '1'
  end

  it "should find the User/Post relationships through the Comment :belongs_to methods" do
    @c1.user.id.should == '1'
    @c1.post.id.should == '1'
  end

end
