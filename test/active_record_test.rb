require File.dirname(__FILE__) + '/test_helper'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_people_table
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :people do |t|
        t.string   :encrypted_email
        t.string   :password
        t.string   :encrypted_credentials
        t.string   :salt
      end
    end
  end
end

# The table needs to exist before defining the class
create_people_table

class Person < ActiveRecord::Base
  attr_encrypted :email, :key => 'a secret key'
  attr_encrypted :credentials, :key => Proc.new { |user| Huberry::Encryptor.encrypt(:value => user.salt, :key => 'some private key') }, :marshal => true
  
  def after_initialize
    self.salt ||= Digest::SHA256.hexdigest((Time.now.to_i * rand(5)).to_s)
    self.credentials ||= { :username => 'example', :password => 'test' }
  end
end

class ActiveRecordTest < Test::Unit::TestCase
  
  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_people_table
  end
  
  def test_should_encrypt_email
    @person = Person.create :email => 'test@example.com'
    assert_not_nil @person.encrypted_email
    assert_not_equal @person.email, @person.encrypted_email
    assert_equal @person.email, Person.find(:first).email
  end
  
  def test_should_marshal_and_encrypt_credentials
    @person = Person.create
    assert_not_nil @person.encrypted_credentials
    assert_not_equal @person.credentials, @person.encrypted_credentials
    assert_equal @person.credentials, Person.find(:first).credentials
  end
  
  def test_should_find_by_email
    @person = Person.create(:email => 'test@example.com')
    assert_equal @person, Person.find_by_email('test@example.com')
  end
  
  def test_should_find_by_email_and_password
    Person.create(:email => 'test@example.com', :password => 'invalid')
    @person = Person.create(:email => 'test@example.com', :password => 'test')
    assert_equal @person, Person.find_by_email_and_password('test@example.com', 'test')
  end
  
  def test_should_scope_by_email
    @person = Person.create(:email => 'test@example.com')
    assert_equal @person, Person.scoped_by_email('test@example.com').find(:first) rescue NoMethodError
  end
  
  def test_should_scope_by_email_and_password
    Person.create(:email => 'test@example.com', :password => 'invalid')
    @person = Person.create(:email => 'test@example.com', :password => 'test')
    assert_equal @person, Person.scoped_by_email_and_password('test@example.com', 'test').find(:first) rescue NoMethodError
  end
  
  def test_should_encode_by_default
    assert Person.attr_encrypted_options[:encode]
  end
  
end