# frozen_string_literal: true

if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        RAILS_VERSION = Gem::Version.new(::ActiveRecord.version)
        class << self
          def prepend_features(obj)
            obj.instance_exec do
              extend ::AttrEncrypted
              class << self
                prepend ::AttrEncrypted::Adapters::ActiveRecord::ClassMethods
              end
              prepend ::AttrEncrypted::Adapters::ActiveRecord::InstanceMethods
              self.attr_encrypted_options[:encode] = true
            end
          end
        end

        module ClassMethods # :nodoc:
          # <tt>attr_encrypted</tt> method
          def attr_encrypted(*attrs)
            super
            options = attrs.extract_options! || {}
            attr    = attrs.pop
            options.merge! encrypted_attributes[attr] # FIXME: this should be used somewhere
            attribute attr
            # debugger
            define_attribute_method attr #FIXME: Why is this trying to connect to the database?
          end
          alias_method :attr_encryptor, :attr_encrypted


          def attribute_instance_methods_as_symbols_available?
            connected? && table_exists?
          end

          # https://github.com/attr-encrypted/attr_encrypted/issues/68
          # def reload(*args, &block)
          #   result = reload_without_attr_encrypted(*args, &block)
          #   self.class.encrypted_attributes.keys.each do |attribute_name|
          #     instance_variable_set("@#{attribute_name}", nil)
          #   end
          #   result
          # end
          # alias_method :reload_without_attr_encrypted, :reload
        end

        module InstanceMethods

        protected
        def is_decrypted_attribute?(attr)
          return nil unless attr.respond_to?(:to_sym)

          self.class.encrypted_attributes.key?(attr.to_sym)
        end

        def decrypted_attribute_name(attr)
          return nil unless attr.respond_to?(:to_sym)
          return attr.to_sym if is_decrypted_attribute?(attr.to_sym)

          self.class.encrypted_attributes.values.detect do |enc_attr|
            enc_attr[:attribute].to_sym == attr.to_sym
          end&.fetch(:name)
        end

        def encrypted_attribute_column(attr)
          return nil unless attr.respond_to?(:to_sym)

          self.class.encrypted_attributes.dig(attr.to_sym, :attribute) ||
            encrypted_attribute_column(decrypted_attribute_name(attr.to_sym))
        end

        def is_encrypted_column?(attr)
          return nil unless attr.respond_to?(:to_sym)

          encrypted_attribute_column(attr).present?
        end

        def attr_encrypted_column(attr)
          self.class.encrypted_attributes[decrypted_attribute_name(attr)]
        end

        # def encrypted_attributes_with_dep(attr)
        #   self.class.encrypted_attributes.
        # end

        def _write_attribute(attr, value)
          enc_config = attr_encrypted_column(attr)
          super(attr, value).tap do |result|
            if is_encrypted_column?(attr)
              super(enc_config[:name], decrypt(enc_config[:name], value))
            elsif is_decrypted_attribute?(attr)
              super(enc_config[:attribute], encrypt(enc_config[:name], value))
            end
          end
        end

          # def _read_attribute(attr)
          #   return super unless self.class.encrypted_attributes.key?(attr.to_sym)
          #   if self.class.encrypted_attributes.key?(attr.to_sym)
          #     elsif self.class.encrypted_attributes[attr.to_sym].fetch(:attribute)
          #   end
          #
          #   encryption_settings = self.class.encrypted_attributes[attr.to_sym]
          #   # TODO: cache decryption
          #   encrypted_value = read_attribute(encryption_settings.fetch(:attribute))
          #   _write_attribute(attr, decrypt(attr.to_sym, encrypted_value), internal: true)
          #   super
          # end

          # Allows you to use dynamic methods like <tt>find_by_email</tt> or <tt>scoped_by_email</tt> for
          # encrypted attributes
          #
          # NOTE: This only works when the <tt>:key</tt> option is specified as a string (see the README)
          #
          # This is useful for encrypting fields like email addresses. Your user's email addresses
          # are encrypted in the database, but you can still look up a user by email for logging in
          #
          # Example
          #
          #   class User < ActiveRecord::Base
          #     attr_encrypted :email, key: 'secret key'
          #   end
          #
          #   User.find_by_email_and_password('test@example.com', 'testing')
          #   # results in a call to
          #   User.find_by_encrypted_email_and_password('the_encrypted_version_of_test@example.com', 'testing')
          def method_missing_with_attr_encrypted(method, *args, &block)
            if match = /^(find|scoped)_(all_by|by)_([_a-zA-Z]\w*)$/.match(method.to_s)
              attribute_names = match.captures.last.split('_and_')
              attribute_names.each_with_index do |attribute, index|
                if attr_encrypted?(attribute) && encrypted_attributes[attribute.to_sym][:mode] == :single_iv_and_salt
                  args[index] = send("encrypt_#{attribute}", args[index])
                  warn "DEPRECATION WARNING: This feature will be removed in the next major release."
                  attribute_names[index] = encrypted_attributes[attribute.to_sym][:attribute]
                end
              end
              method = "#{match.captures[0]}_#{match.captures[1]}_#{attribute_names.join('_and_')}".to_sym
            end
            method_missing_without_attr_encrypted(method, *args, &block)
          end
        end
      end
    end
  end
end
ActiveSupport.on_load(:active_record) do
  prepend AttrEncrypted::Adapters::ActiveRecord
end