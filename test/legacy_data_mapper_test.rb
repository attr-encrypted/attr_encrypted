require File.expand_path('../test_helper', __FILE__)

DataMapper.setup(:default, 'sqlite3::memory:')

class LegacyClient
  include DataMapper::Resource

  property :id, Serial
  property :encrypted_email, String
  property :encrypted_credentials, Text
  property :salt, String

  attr_encrypted :email, :key => 'a secret key'
  attr_encrypted :credentials, :key => Proc.new { |client| Encryptor.encrypt(:value => client.salt, :key => 'some private key') }, :marshal => true

  def initialize(attrs = {})
    super attrs
    self.salt ||= Digest::SHA1.hexdigest((Time.now.to_i * rand(5)).to_s)
    self.credentials ||= { :username => 'example', :password => 'test' }
  end
end

DataMapper.auto_migrate!

class LegacyDataMapperTest < Test::Unit::TestCase

  def setup
    LegacyClient.all.each(&:destroy)
  end

  def test_should_encrypt_email
    @client = LegacyClient.new :email => 'test@example.com'
    assert @client.save
    assert_not_nil @client.encrypted_email
    assert_not_equal @client.email, @client.encrypted_email
    assert_equal @client.email, LegacyClient.first.email
  end

  def test_should_marshal_and_encrypt_credentials
    @client = LegacyClient.new
    assert @client.save
    assert_not_nil @client.encrypted_credentials
    assert_not_equal @client.credentials, @client.encrypted_credentials
    assert_equal @client.credentials, LegacyClient.first.credentials
    assert LegacyClient.first.credentials.is_a?(Hash)
  end

  def test_should_encode_by_default
    assert LegacyClient.attr_encrypted_options[:encode]
  end

end
