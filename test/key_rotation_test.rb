# frozen_string_literal: true
# encoding: UTF-8

require_relative 'test_helper'

class KeyRotationTest < Minitest::Test
  class FakeRotatable
    extend AttrEncrypted

    self.attr_encrypted_options[:mode] = :single_iv_and_salt

    def initialize(value: nil)
      self.value = value
    end

    attr_accessor(
      :value,
    )
  end

  def setup
    @old_config = generate_attr_encrypted_config
    @new_config = generate_attr_encrypted_config

    FakeRotatable.class_eval do
      attr_encrypted(
        :value,
        *@old_config,
      )
    end
  end

  def teardown
    Object.send(:remove_const, :FakeRotatable) if Object.const_defined?("FakeRotatable")
  end

  def test_decrypt_error_while_not_rotataing_keys_raises_cipher_error
    original = instance_with_attr_encrypted_config(**@old_config)
    original.value = "cleartext-value"

    with_wrong_key = instance_with_attr_encrypted_config(**@new_config)
    with_wrong_key.encrypted_value = original.encrypted_value

    assert_raises(OpenSSL::Cipher::CipherError, "expected OpenSSL::Cipher::CipherError was not raised") do
      with_wrong_key.value
    end
  end

  def test_decrypt_error_when_rotating_keys_retries_with_the_old_key
    original = instance_with_attr_encrypted_config(**@old_config)
    original.value = "cleartext-value"
    rotation_handler_instance = Minitest::Mock.new
    rotation_handler_instance.expect(:call, true)

    rotating = setup_key_rotation(
      from_config: @old_config,
      to_config: @new_config,
      rotation_handler: mock_rotation_handler_class(instance: rotation_handler_instance)
    )

    assert "cleartext_value", rotating.value
  end

  def test_rotation_invokes_the_rotation_handler
    original = instance_with_attr_encrypted_config(**@old_config)
    original.value = "cleartext-value"
    rotation_handler_instance = Minitest::Mock.new
    rotation_handler_instance.expect(:call, true)

    rotating = setup_key_rotation(
      from_config: @old_config,
      to_config: @new_config,
      rotation_handler: mock_rotation_handler_class(instance: rotation_handler_instance)
    )
    rotating.value

    rotation_handler_instance.verify
  end

  def test_rotation_invokes_the_rotation_error_handler_when_rotation_fails
    rotation_handler_instance = Minitest::Mock.new
    rotation_handler_instance.expect(:call, true)
    rotation_error_handler_instance = Minitest::Mock.new
    rotation_error_handler_instance.expect(:call, true)
    wrong_key = generate_key
    original = instance_with_attr_encrypted_config(**@old_config)
    original.value = "cleartext-value"
    rotating = setup_key_rotation(
      from_config: @old_config.merge(key: wrong_key),
      to_config: @new_config,
      rotation_handler: mock_rotation_handler_class(instance: rotation_handler_instance),
      rotation_error_handler: mock_rotation_error_handler_class(instance: rotation_error_handler_instance)
    )
    rotating.encrypted_value = original.encrypted_value

    rotating.value

    rotation_error_handler_instance.verify
  end

  def instance_with_attr_encrypted_config(key: generate_key, iv: generate_iv)
    FakeRotatable.class_eval do
      attr_encrypted(
        :value,
        key: key,
        iv: iv,
      )
    end

    FakeRotatable.new
  end

  def setup_key_rotation(from_config: @old_config, to_config: @new_config, rotation_handler: proc {}, rotation_error_handler: proc {})
    original = instance_with_attr_encrypted_config(**from_config)
    original.value = "cleartext-value"
    FakeRotatable.class_eval do
      attr_encrypted(
        :value,
        key: to_config.fetch(:key),
        iv: to_config.fetch(:iv),
        old_key: from_config.fetch(:key),
        old_iv: from_config.fetch(:iv),
        rotation_handler: rotation_handler,
        rotation_error_handler: rotation_error_handler,
      )
    end
    rotating = FakeRotatable.new
    rotating.encrypted_value = original.encrypted_value

    rotating
  end

  def generate_attr_encrypted_config(key: generate_key, iv: generate_iv)
    {
      key: key,
      iv: iv,
    }
  end

  def generate_key
    SecureRandom.random_bytes(32)
  end

  def generate_iv
    SecureRandom.random_bytes(12)
  end

  def mock_rotation_handler_class(instance:)
    mock_rotation_handler_class = Minitest::Mock.new
    mock_rotation_handler_class.expect(:new, instance, [FakeRotatable, :value, "cleartext-value", String, Hash])
    mock_rotation_handler_class.expect(:!, false) # For presence checks
    3.times { mock_rotation_handler_class.expect(:is_a?, false, [Symbol]) }

    mock_rotation_handler_class
  end

  def mock_rotation_error_handler_class(instance:)
    mock_rotation_handler_class = Minitest::Mock.new
    mock_rotation_handler_class.expect(:new, instance, [FakeRotatable, :value, StandardError, String, Hash])
    mock_rotation_handler_class.expect(:!, false) # For presence checks
    3.times { mock_rotation_handler_class.expect(:is_a?, false, [Symbol]) }

    mock_rotation_handler_class
  end
end
