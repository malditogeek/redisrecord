require File.dirname(__FILE__) + '/spec_helper'

describe "RedisRecord" do

  before(:each) do
    @c = Customer.new
  end

  after do
    r = Redis.new
    r.select_db 15
    r.flush_db
  end

  it "should allow to add any attribute to an instance" do
    @c.name = 'foo'
    @c.age  = 25
    @c.name.should == 'foo'
    @c.age.should == 25
  end

  it "should have an attribute accesor with the instance attributes" do
    @c.name = 'foo'
    @c.age  = 25
    @c.attrs.map {|a| a.to_s }.sort.should == ['age', 'name']
  end

  it "should be 'dirty' if some of the instance attributes aren't saved" do
    @c.name = 'foo'
    @c.dirty?.should == true
  end

  it "should not be 'dirty' anymore once saved" do 
    @c.name = 'foo'
    @c.save
    @c.dirty?.should == false
  end

  it "should be 'dirty' again after add a new attribute or update an existing one" do
    @c.name = 'foo'
    @c.save
    @c.age  = 25
    @c.dirty?.should == true
    @c.save
    @c.name = 'bar'
    @c.dirty?.should == true
  end

  it "should have :id and timestamp attributes after saved" do
    @c.name = 'foo'
    saved_attributes = @c.save
    saved_attributes.map {|a| a.to_s }.sort.should == ['created_at','id','name','updated_at']
  end

  it "should save only: the new and the updated attributes, and update the :updated_at timestamp" do
    @c.name = 'foo'
    @c.lastname = 'bar'
    saved_attributes = @c.save
    saved_attributes.map {|a| a.to_s }.sort.should == ['created_at','id','lastname','name','updated_at']
    @c.age = 25
    @c.lastname = 'baz'
    new_saved_attributes = @c.save
    new_saved_attributes.map {|a| a.to_s }.sort.should == ['age','lastname','updated_at']
  end

end
