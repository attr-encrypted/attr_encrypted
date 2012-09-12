# -*- encoding: utf-8 -*-
require File.expand_path('../test_helper', __FILE__)

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
      create_table :projects do |t|
        t.string   :encrypted_name
      end
    end
  end
end

# The table needs to exist before defining the class
create_people_table

ActiveRecord::MissingAttributeError = ActiveModel::MissingAttributeError unless defined?(ActiveRecord::MissingAttributeError)

class Person < ActiveRecord::Base
  attr_encrypted :email, :key => 'a secret key'
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
  validates_uniqueness_of :encrypted_email
end

class Project < ActiveRecord::Base
  attr_encryptor :name, :key => 'a secret key'
end

class ActiveRecordTest < Test::Unit::TestCase

  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_people_table
  end

  def test_should_decrypt_with_correct_encoding
    if defined?(Encoding)
      @person = Person.create :email => 'test@example.com'
      assert_equal 'UTF-8', Person.find(:first).email.encoding.name
    end
  end

  def test_should_encrypt_email
    @person = Person.create :email => 'test@example.com'
    assert_not_nil @person.encrypted_email
    assert_not_equal @person.email, @person.encrypted_email
    assert_equal @person.email, Person.find(:first).email
  end

  def test_should_properly_detects_active_record_object_by_attribute_methods
    @project = Project.create :name => 'test@example.com'
    assert_not_nil Project.find(:first).name
    assert_equal @project.name, Project.find(:first).name
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

  def test_should_validate_presence_of_email
    @person = PersonWithValidation.new
    assert !@person.valid?
    assert !@person.errors[:email].empty? || @person.errors.on(:email)
  end

  def test_should_validate_uniqueness_of_email
    @person = PersonWithValidation.new :email => 'test@example.com'
    assert @person.save
    @person2 = PersonWithValidation.new :email => @person.email
    assert !@person2.valid?
    assert !@person2.errors[:encrypted_email].empty? || @person2.errors.on(:encrypted_email)
  end

end
