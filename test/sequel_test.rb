require File.expand_path('../test_helper', __FILE__)

DB.create_table :humans do
  primary_key :id
  column :encrypted_email, :string
  column :encrypted_email_salt, String
  column :encrypted_email_iv, :string
  column :password, :string
  column :encrypted_credentials, :string
  column :encrypted_credentials_iv, :string
  column :encrypted_credentials_salt, String
end

class Human < Sequel::Model(:humans)
  self.attr_encrypted_options[:mode] = :per_attribute_iv_and_salt

  attr_encrypted :email, :key => SECRET_KEY
  attr_encrypted :credentials, :key => SECRET_KEY, :marshal => true

  def after_initialize(attrs = {})
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

    @human = Human.new :credentials => { :username => 'example', :password => 'test' }
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
