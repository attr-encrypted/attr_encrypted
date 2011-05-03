require File.expand_path('../test_helper', __FILE__)

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_people_table
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :people do |t|
        t.string   :encrypted_age
        t.string   :encrypted_height
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

ActiveRecord::MissingAttributeError = ActiveModel::MissingAttributeError unless defined?(ActiveRecord::MissingAttributeError)

class Person < ActiveRecord::Base
  attr_encrypted :email, :key => 'a secret key'
  attr_encrypted :height, :key => 'another secret key', :type => Float
  attr_encrypted :age, :key => 'a third secret key', :type => Integer
  attr_encrypted :credentials, :key => Proc.new { |user| Encryptor.encrypt(:value => user.salt, :key => 'some private key') }, :marshal => true

  ActiveSupport::Deprecation.silenced = true
  def after_initialize; end
  ActiveSupport::Deprecation.silenced = false

  after_initialize :initialize_salt_and_credentials

  protected

    def initialize_salt_and_credentials
      self.salt ||= Digest::SHA256.hexdigest((Time.now.to_i * rand(5)).to_s)
      self.credentials ||= { :username => 'example', :password => 'test' }
    rescue ActiveRecord::MissingAttributeError
    end
end

class PersonWithValidation < Person
  validates_presence_of :email
  validates_presence_of :height
  validates_presence_of :age
  validates_numericality_of :height, :greater_than_or_equal_to => 0
  validates_numericality_of :age, :only_integer => true
  validates_uniqueness_of :encrypted_email
  validates_uniqueness_of :encrypted_age
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

  def test_should_encrypt_height
    @person = Person.create :height => 0.99
    assert_not_nil @person.encrypted_height
    assert_not_equal @person.height, @person.encrypted_height
    assert_equal @person.height, Person.find(:first).height
    assert(Person.find(:first).height.kind_of? Float)
  end
  
  def test_should_encrypt_age
    @person = Person.create :age => 42
    assert_not_nil @person.encrypted_age
    assert_not_equal @person.age, @person.encrypted_age
    assert_equal @person.age, Person.find(:first).age
    assert(Person.find(:first).age.kind_of? Integer)
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
  
  def test_should_find_by_age
    @person = Person.create(:age => 42)
    assert_equal @person, Person.find_by_age(42)
  end
  
  def test_should_find_by_height
    @person = Person.create(:height => 0.6)
    assert_equal @person, Person.find_by_height(0.6)
  end

  def test_should_find_by_email_and_password
    Person.create(:email => 'test@example.com', :password => 'invalid')
    @person = Person.create(:email => 'test@example.com', :password => 'test')
    assert_equal @person, Person.find_by_email_and_password('test@example.com', 'test')
  end

  def test_should_find_by_email_and_password_and_age_and_height
    Person.create(:email => 'test@example.com', :password => 'invalid')
    @person = Person.create(:email => 'test@example.com', :password => 'test', :age => 42, :height => 0.2)
    assert_equal @person, Person.find_by_email_and_password_and_age_and_height('test@example.com', 'test', 42, 0.2)
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
  
  def test_should_scope_by_email_and_password_and_age_and_height
    Person.create(:email => 'test@example.com', :password => 'invalid')
    @person = Person.create(:email => 'test@example.com', :password => 'test', :age => 43, :height => 0.2)
    assert_equal @person, Person.scoped_by_email_and_password_and_age_and_height('test@example.com', 'test', 43, 0.2).find(:first) rescue NoMethodError
  end

  def test_should_encode_by_default
    assert Person.attr_encrypted_options[:encode]
  end

  def test_should_validate_presence_of_email
    @person = PersonWithValidation.new(:age => 44)
    assert !@person.valid?
    assert !@person.errors[:email].empty? 
  end
  
  def test_should_validate_presence_of_age
    @person = PersonWithValidation.new :email => 'test@example.com', :height => 1.2
    assert !@person.valid?
    assert !@person.errors[:age].empty?
    @person = PersonWithValidation.new :email => 'test@example.com', :age => 47.3, :height => 1.2
    assert !@person.valid?
    assert !@person.errors[:age].empty?
  end
  
  def test_should_validate_uniqueness_of_email
    @person = PersonWithValidation.new :email => 'test@example.com', :age => 45, :height => 1.2
    assert @person.save
    @person2 = PersonWithValidation.new :email => @person.email, :age => 46, :height => 1.2
    assert !@person2.valid?
    assert !@person2.errors[:encrypted_email].empty? 
  end

  def test_should_validate_uniqueness_of_age
    @person = PersonWithValidation.new :email => 'test@example.com', :age => 47, :height => 1.2
    assert @person.save
    @person2 = PersonWithValidation.new :email => 'test2@example.com', :age => 47, :height => 1.2
    assert !@person2.valid?
    assert !@person2.errors[:encrypted_age].empty?
  end
  
  def test_should_validate_height
    @person = PersonWithValidation.new :email => 'test@example.com', :age => 47, :height => 'a'
    assert !@person.valid?
    assert !@person.errors[:height].empty? 
    @person = PersonWithValidation.new :email => 'test@example.com', :age => 47, :height => -1.2
    assert !@person.valid?
    assert !@person.errors[:height].empty? 
    @person = PersonWithValidation.new :email => 'test@example.com', :age => 47, :height => 1.2
    assert @person.save
  end
end
