require File.expand_path('../test_helper', __FILE__)

if RUBY_VERSION < '1.9.3'
  Mongoid::Config.master = Mongo::Connection.new.db('mongoid_test')
else
  Mongoid::Config.connect_to('mongoid_test')
end

class MongoidUser
  include Mongoid::Document
  field :encrypted_email, :type => String
  attr_encrypted :email, :key => 'a secret key'
end

class MongoidTest < Test::Unit::TestCase
  def setup
    MongoidUser.destroy_all
  end

  def test_should_encrypt_email
    @mongoid_user = MongoidUser.new :email => 'test@example.com'
    assert @mongoid_user.save
    assert_not_nil @mongoid_user.encrypted_email
    assert_not_equal @mongoid_user.email, @mongoid_user.encrypted_email
    assert_equal @mongoid_user.email, MongoidUser.first.email
  end
end
