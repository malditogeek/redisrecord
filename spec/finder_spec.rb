require File.dirname(__FILE__) + '/spec_helper'

describe "RedisRecord" do

  before do
    @c1 = Customer.new
    @c1.name = 'Foo'
    @c1.age = 25
    @c1.save

    @c2 = Customer.new
    @c2.name = 'Bar'
    @c2.age = 30
    @c2.save

    @c3 = Customer.new
    @c3.name = 'Baz'
    @c3.age = 35
    @c3.save
  end

  after do
    r = Redis.new
    #r.select_db 15
    r.flush_db
  end

  it "should find a stored Customer by id" do
    customer = Customer.find(@c1.id)
    customer.attrs.map {|a| a.to_s }.sort.should == ['age','created_at','id','name','updated_at']
    customer.new_record?.should == false
    customer.dirty?.should == false
  end

  it "should find an array of Customers by id" do
    customers = Customer.find(@c1.id, @c2.id)
    customers.length.should == 2
    customers.each do |c|
      c.attrs.map {|a| a.to_s }.sort.should == ['age','created_at','id','name','updated_at']
      c.new_record?.should == false
      c.dirty?.should == false
      ['Foo', 'Bar'].include?(c.name).should == true
    end
  end

  it "should find the :first Customer" do
    customer = Customer.find(:first)
    customer.name.should == 'Foo'
  end

  it "should find the :last Customer" do
    customer = Customer.find(:last)
    customer.name.should == 'Baz'
  end

  it "should find :all the Customers" do
    customers = Customer.find(:all)
    customers.each do |c|
      c.attrs.map {|a| a.to_s }.sort.should == ['age','created_at','id','name','updated_at']
      c.new_record?.should == false
      c.dirty?.should == false
      [@c1.id, @c2.id, @c3.id].map {|id| id.to_s}.include?(c.id).should == true
    end
  end

  it "should return the last 10 or less Customers in descendent order of creation when sorting by :created_at" do
    customers = Customer.sort_by(:created_at)
    names_by_created_at = ['Baz', 'Bar', 'Foo']
    until customers.empty?
      customers.pop.name.should == names_by_created_at.pop
    end
  end

  it "should return the first 2 Customers in ascendent order when sorting by :age" do
    customers = Customer.sort_by(:age, :limit => 2, :order => 'ALPHA ASC')
    ordered_ages = ['25','30']
    until customers.empty?
      customers.pop.age.should == ordered_ages.pop
    end
  end

end
