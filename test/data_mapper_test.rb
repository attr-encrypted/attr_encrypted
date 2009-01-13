require File.dirname(__FILE__) + '/test_helper'

DataMapper.setup(:default, "sqlite3::memory:")

class Client
  include DataMapper::Resource
  
  property :id, Serial
  property :encrypted_email, String
  property :encrypted_credentials, Text
  property :salt, String
  
  attr_encrypted :email, :key => 'a secret key'
  attr_encrypted :credentials, :key => Proc.new { |client| Huberry::Encryptor.encrypt(:value => client.salt, :key => 'some private key') }, :marshal => true
  
  def initialize(attrs = {})
    super attrs
    self.salt ||= Digest::SHA1.hexdigest((Time.now.to_i * rand(5)).to_s)
    self.credentials ||= { :username => 'example', :password => 'test' }
  end
end

DataMapper.auto_migrate!

class DataMapperTest < Test::Unit::TestCase
  
  def setup
    Client.all.each(&:destroy)
  end
  
  def test_should_encrypt_email
    @client = Client.new :email => 'test@example.com'
    assert @client.save
    assert_not_nil @client.encrypted_email
    assert_not_equal @client.email, @client.encrypted_email
    assert_equal @client.email, Client.first.email
  end
  
  def test_should_marshal_and_encrypt_credentials
    @client = Client.new
    assert @client.save
    assert_not_nil @client.encrypted_credentials
    assert_not_equal @client.credentials, @client.encrypted_credentials
    assert_equal @client.credentials, Client.first.credentials
    assert Client.first.credentials.is_a?(Hash)
  end
  
  def test_should_encode_by_default
    assert Client.attr_encrypted_options[:encode]
  end
  
end