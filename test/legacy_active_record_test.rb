# -*- encoding: utf-8 -*-
require File.expand_path('../test_helper', __FILE__)

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_people_table
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :legacy_people do |t|
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

class LegacyPerson < ActiveRecord::Base
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

class LegacyPersonWithValidation < LegacyPerson
  validates_presence_of :email
  validates_uniqueness_of :encrypted_email
end

class LegacyActiveRecordTest < Minitest::Test

  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_people_table
  end

  def test_should_decrypt_with_correct_encoding
    if defined?(Encoding)
      @person = LegacyPerson.create :email => 'test@example.com'
      assert_equal 'UTF-8', LegacyPerson.find(:first).email.encoding.name
    end
  end

  def test_should_encrypt_email
    @person = LegacyPerson.create :email => 'test@example.com'
    refute_nil @person.encrypted_email
    refute_equal @person.email, @person.encrypted_email
    assert_equal @person.email, LegacyPerson.find(:first).email
  end

  def test_should_marshal_and_encrypt_credentials
    @person = LegacyPerson.create
    refute_nil @person.encrypted_credentials
    refute_equal @person.credentials, @person.encrypted_credentials
    assert_equal @person.credentials, LegacyPerson.find(:first).credentials
  end

  def test_should_find_by_email
    @person = LegacyPerson.create(:email => 'test@example.com')
    assert_equal @person, LegacyPerson.find_by_email('test@example.com')
  end

  def test_should_find_by_email_and_password
    LegacyPerson.create(:email => 'test@example.com', :password => 'invalid')
    @person = LegacyPerson.create(:email => 'test@example.com', :password => 'test')
    assert_equal @person, LegacyPerson.find_by_email_and_password('test@example.com', 'test')
  end

  def test_should_scope_by_email
    @person = LegacyPerson.create(:email => 'test@example.com')
    assert_equal @person, LegacyPerson.scoped_by_email('test@example.com').find(:first) rescue NoMethodError
  end

  def test_should_scope_by_email_and_password
    LegacyPerson.create(:email => 'test@example.com', :password => 'invalid')
    @person = LegacyPerson.create(:email => 'test@example.com', :password => 'test')
    assert_equal @person, LegacyPerson.scoped_by_email_and_password('test@example.com', 'test').find(:first) rescue NoMethodError
  end

  def test_should_encode_by_default
    assert LegacyPerson.attr_encrypted_options[:encode]
  end

  def test_should_validate_presence_of_email
    @person = LegacyPersonWithValidation.new
    assert !@person.valid?
    assert !@person.errors[:email].empty? || @person.errors.on(:email)
  end

  def test_should_validate_uniqueness_of_email
    @person = LegacyPersonWithValidation.new :email => 'test@example.com'
    assert @person.save
    @person2 = LegacyPersonWithValidation.new :email => @person.email
    assert !@person2.valid?
    assert !@person2.errors[:encrypted_email].empty? || @person2.errors.on(:encrypted_email)
  end

end
