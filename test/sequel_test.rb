require File.dirname(__FILE__) + '/test_helper'

DB = Sequel.sqlite

DB.create_table :humans do
  primary_key :id
  column :encrypted_email, :string
  column :password, :string
  column :encrypted_credentials, :string
  column :salt, :string
end

class Human < Sequel::Model(:humans)  
  attr_encrypted :email, :key => 'a secret key'
  attr_encrypted :credentials, :key => Proc.new { |human| Huberry::Encryptor.encrypt(:value => human.salt, :key => 'some private key') }, :marshal => true
  
  def after_initialize(attrs = {})
    self.salt ||= Digest::SHA1.hexdigest((Time.now.to_i * rand(5)).to_s)
    self.credentials ||= { :username => 'example', :password => 'test' }
  end
end

class SequelTest < Test::Unit::TestCase
  
  def setup
    Human.all.each(&:destroy)
  end
  
  def test_should_encrypt_email
    @human = Human.new :email => 'test@example.com'
    assert @human.save
    assert_not_nil @human.encrypted_email
    assert_not_equal @human.email, @human.encrypted_email
    assert_equal @human.email, Human.first.email
  end
  
  def test_should_marshal_and_encrypt_credentials
    @human = Human.new
    assert @human.save
    assert_not_nil @human.encrypted_credentials
    assert_not_equal @human.credentials, @human.encrypted_credentials
    assert_equal @human.credentials, Human.first.credentials
    assert Human.first.credentials.is_a?(Hash)
  end
  
  def test_should_encode_by_default
    assert Human.attr_encrypted_options[:encode]
  end
  
end