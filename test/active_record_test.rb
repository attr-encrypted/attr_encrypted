require File.expand_path('../test_helper', __FILE__)

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_tables
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :people do |t|
        t.string   :encrypted_email
        t.string   :password
        t.string   :encrypted_credentials
        t.binary   :salt
        t.string   :encrypted_email_salt
        t.string   :encrypted_credentials_salt
        t.string   :encrypted_email_iv
        t.string   :encrypted_credentials_iv
      end
      create_table :accounts do |t|
        t.string :encrypted_password
        t.string :encrypted_password_iv
        t.string :encrypted_password_salt
      end
      create_table :users do |t|
        t.string :login
        t.string :encrypted_password
        t.boolean :is_admin
      end
      create_table :prime_ministers do |t|
        t.string :encrypted_name
      end
    end
  end
end

# The table needs to exist before defining the class
create_tables

ActiveRecord::MissingAttributeError = ActiveModel::MissingAttributeError unless defined?(ActiveRecord::MissingAttributeError)
ActiveRecord::Base.logger = Logger.new(nil) if ::ActiveRecord::VERSION::STRING < "3.0"

if ::ActiveRecord::VERSION::STRING > "4.0"
  module Rack
    module Test
      class UploadedFile; end
    end
  end

  require 'action_controller/metal/strong_parameters'
end

class Person < ActiveRecord::Base
  self.attr_encrypted_options[:mode] = :per_attribute_iv_and_salt
  attr_encrypted :email, :key => SECRET_KEY
  attr_encrypted :credentials, :key => Proc.new { |user| Encryptor.encrypt(:value => user.salt, :key => SECRET_KEY) }, :marshal => true

  if ActiveRecord::VERSION::STRING < "3"
    def after_initialize
      initialize_salt_and_credentials
    end
  else
    after_initialize :initialize_salt_and_credentials
  end

  protected

  def initialize_salt_and_credentials
    self.salt ||= Digest::SHA256.hexdigest((Time.now.to_i * rand(1000)).to_s)[0..15]
    self.credentials ||= { :username => 'example', :password => 'test' }
  end
end

class PersonWithValidation < Person
  validates_presence_of :email
end

class PersonWithProcMode < Person
  attr_encrypted :email,       :key => SECRET_KEY, :mode => Proc.new { :per_attribute_iv_and_salt }
  attr_encrypted :credentials, :key => SECRET_KEY, :mode => Proc.new { :single_iv_and_salt }
end

class Account < ActiveRecord::Base
  attr_accessor :key
  attr_encrypted :password, :key => Proc.new {|account| account.key}
end

class PersonWithSerialization < ActiveRecord::Base
  self.table_name = 'people'
  attr_encrypted :email, :key => 'a secret key'
  serialize :password
end

class UserWithProtectedAttribute < ActiveRecord::Base
  self.table_name = 'users'
  attr_encrypted :password, :key => 'a secret key'
  attr_protected :is_admin if ::ActiveRecord::VERSION::STRING < "4.0"
end

class PersonUsingAlias < ActiveRecord::Base
  self.table_name = 'people'
  attr_encryptor :email, :key => 'a secret key'
end

class PrimeMinister < ActiveRecord::Base
  attr_encrypted :name, :marshal => true, :key => 'SECRET_KEY'
end

class ActiveRecordTest < Minitest::Test

  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_tables
    Account.create!(:key => SECRET_KEY, :password => "password")
  end

  def test_should_encrypt_email
    @person = Person.create :email => 'test@example.com'
    refute_nil @person.encrypted_email
    refute_equal @person.email, @person.encrypted_email
    assert_equal @person.email, Person.find(:first).email
  end

  def test_should_marshal_and_encrypt_credentials
    @person = Person.create
    refute_nil @person.encrypted_credentials
    refute_equal @person.credentials, @person.encrypted_credentials
    assert_equal @person.credentials, Person.find(:first).credentials
  end

  def test_should_encode_by_default
    assert Person.attr_encrypted_options[:encode]
  end

  def test_should_validate_presence_of_email
    @person = PersonWithValidation.new
    assert !@person.valid?
    assert !@person.errors[:email].empty? || @person.errors.on(:email)
  end

  def test_should_encrypt_decrypt_with_iv
    @person = Person.create :email => 'test@example.com'
    @person2 = Person.find(@person.id)
    refute_nil @person2.encrypted_email_iv
    assert_equal 'test@example.com', @person2.email
  end

  def test_should_ensure_attributes_can_be_deserialized
    @person = PersonWithSerialization.new :email => 'test@example.com', :password => %w(an array of strings)
    @person.save
    assert_equal @person.password, %w(an array of strings)
  end

  def test_should_create_an_account_regardless_of_arguments_order
    Account.create!(:key => SECRET_KEY, :password => "password")
    Account.create!(:password => "password" , :key => SECRET_KEY)
  end

  def test_should_set_attributes_regardless_of_arguments_order
    Account.new.attributes = { :password => "password" , :key => SECRET_KEY }
  end

  def test_should_preserve_hash_key_type
    hash = { :foo => 'bar' }
    account = Account.create!(:key => hash)
    assert_equal account.key, hash
  end

  if ::ActiveRecord::VERSION::STRING > "4.0"
    def test_should_assign_attributes
      @user = UserWithProtectedAttribute.new :login => 'login', :is_admin => false
      @user.attributes = ActionController::Parameters.new(:login => 'modified', :is_admin => true).permit(:login)
      assert_equal 'modified', @user.login
    end

    def test_should_not_assign_protected_attributes
      @user = UserWithProtectedAttribute.new :login => 'login', :is_admin => false
      @user.attributes = ActionController::Parameters.new(:login => 'modified', :is_admin => true).permit(:login)
      assert !@user.is_admin?
    end

    def test_should_raise_exception_if_not_permitted
      @user = UserWithProtectedAttribute.new :login => 'login', :is_admin => false
      assert_raises ActiveModel::ForbiddenAttributesError do
        @user.attributes = ActionController::Parameters.new(:login => 'modified', :is_admin => true)
      end
    end

    def test_should_raise_exception_on_init_if_not_permitted
      assert_raises ActiveModel::ForbiddenAttributesError do
        @user = UserWithProtectedAttribute.new ActionController::Parameters.new(:login => 'modified', :is_admin => true)
      end
    end
  else
    def test_should_assign_attributes
      @user = UserWithProtectedAttribute.new :login => 'login', :is_admin => false
      @user.attributes = {:login => 'modified', :is_admin => true}
      assert_equal 'modified', @user.login
    end

    def test_should_not_assign_protected_attributes
      @user = UserWithProtectedAttribute.new :login => 'login', :is_admin => false
      @user.attributes = {:login => 'modified', :is_admin => true}
      assert !@user.is_admin?
    end

    def test_should_assign_protected_attributes
      @user = UserWithProtectedAttribute.new :login => 'login', :is_admin => false
      if ::ActiveRecord::VERSION::STRING > "3.1"
        @user.send :assign_attributes, {:login => 'modified', :is_admin => true}, :without_protection => true
      else
        @user.send :attributes=, {:login => 'modified', :is_admin => true}, false
      end
      assert @user.is_admin?
    end
  end

  def test_should_allow_assignment_of_nil_attributes
    @person = Person.new
    assert_nil(@person.attributes = nil)
  end

  def test_should_allow_proc_based_mode
    @person = PersonWithProcMode.create :email => 'test@example.com', :credentials => 'password123'

    # Email is :per_attribute_iv_and_salt
    assert_equal @person.class.encrypted_attributes[:email][:mode].class, Proc
    assert_equal @person.class.encrypted_attributes[:email][:mode].call, :per_attribute_iv_and_salt
    refute_nil @person.encrypted_email_salt
    refute_nil @person.encrypted_email_iv

    # Credentials is :single_iv_and_salt
    assert_equal @person.class.encrypted_attributes[:credentials][:mode].class, Proc
    assert_equal @person.class.encrypted_attributes[:credentials][:mode].call, :single_iv_and_salt
    assert_nil @person.encrypted_credentials_salt
    assert_nil @person.encrypted_credentials_iv
  end

  if ::ActiveRecord::VERSION::STRING > "3.1"
    def test_should_allow_assign_attributes_with_nil
      @person = Person.new
      assert_nil(@person.assign_attributes nil)
    end
  end

  def test_that_alias_encrypts_column
    user = PersonUsingAlias.new
    user.email = 'test@example.com'
    user.save

    refute_nil user.encrypted_email
    refute_equal user.email, user.encrypted_email
    assert_equal user.email, PersonUsingAlias.find(:first).email
  end

  # See https://github.com/attr-encrypted/attr_encrypted/issues/68
  def test_should_invalidate_virtual_attributes_on_reload
    pm = PrimeMinister.new(:name => 'Winston Churchill')
    pm.save!
    assert_equal 'Winston Churchill', pm.name
    pm.name = 'Neville Chamberlain'
    assert_equal 'Neville Chamberlain', pm.name

    result = pm.reload
    assert_equal pm, result
    assert_equal 'Winston Churchill', pm.name
  end
end
