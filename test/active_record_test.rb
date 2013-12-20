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
        t.string   :encrypted_birth_date
      end
      create_table :accounts do |t|
        t.string :encrypted_password
        t.string :encrypted_password_iv
        t.string :encrypted_password_salt
      end
    end
  end
end

# The table needs to exist before defining the class
create_tables

ActiveRecord::MissingAttributeError = ActiveModel::MissingAttributeError unless defined?(ActiveRecord::MissingAttributeError)

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

class Account < ActiveRecord::Base
  attr_accessor :key
  attr_encrypted :password, :key => Proc.new {|account| account.key}
end

class PersonWithSerialization < ActiveRecord::Base
  self.table_name = 'people'
  attr_encrypted :email, :key => 'a secret key'
  serialize :password
end

class PersonWithDateBirthDate < ActiveRecord::Base
  self.table_name = 'people'
  attr_encrypted :birth_date, :marshal => true, :class => Date, :key => "any key"
end

class ActiveRecordTest < Test::Unit::TestCase

  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_tables
    Account.create!(:key => SECRET_KEY, :password => "password")
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
    assert_not_nil @person2.encrypted_email_iv
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

  def test_multiparameter_attributes_on_date
    attributes = { "birth_date(1i)" => "1983", "birth_date(2i)" => "9", "birth_date(3i)" => "17" }
    person = PersonWithDateBirthDate.create(attributes)

    assert_equal Date.new(1983, 9, 17), person.birth_date
  end
end
