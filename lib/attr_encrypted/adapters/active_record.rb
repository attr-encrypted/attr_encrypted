if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        def self.extended(base) # :nodoc:
          base.class_eval do
            attr_encrypted_options[:encode] = true
            class << self
              alias_method_chain :method_missing, :attr_encrypted
              if ::ActiveRecord::VERSION::STRING < "3"
                alias_method :undefine_attribute_methods, :reset_column_information
              end
            end

            if ::ActiveRecord::VERSION::STRING < "3.0" || ::ActiveRecord::VERSION::STRING > "3.1"
              def assign_attributes_with_attr_encrypted(*args)
                attributes = args.shift.symbolize_keys
                encrypted_attributes = self.class.encrypted_attributes.keys
                assign_attributes_without_attr_encrypted attributes.except(*encrypted_attributes), *args
                assign_attributes_without_attr_encrypted attributes.slice(*encrypted_attributes), *args
              end
              alias_method_chain :assign_attributes, :attr_encrypted
            else
              def attributes_with_attr_encrypted=(attributes)
                attributes = attributes.symbolize_keys
                encrypted_attributes = self.class.encrypted_attributes.keys
                self.attributes_without_attr_encrypted = attributes.except(*encrypted_attributes)
                self.attributes_without_attr_encrypted = attributes.slice(*encrypted_attributes)
              end
              alias_method_chain :attributes=, :attr_encrypted
            end
          end
        end

        protected

          # Ensures the attribute methods for db fields have been defined before calling the original 
          # <tt>attr_encrypted</tt> method
          def attr_encrypted(*attrs)
            define_attribute_methods rescue nil
            super
            undefine_attribute_methods
            options = attrs.last.is_a?(Hash) ? attrs.pop : {}

            if klass = options.delete(:class)
              attribute_sym = attrs.first.to_sym
              self.encrypted_attribute_class_wrappers[attribute_sym] = EncryptedAttributeClassWrapper.new(klass)
            end

            new_attrs = attrs + [options]
            new_attrs.reject { |attr| attr.is_a?(Hash) }.each { |attr| alias_method "#{attr}_before_type_cast", attr }
          end

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
          #     attr_encrypted :email, :key => 'secret key'
          #   end
          #
          #   User.find_by_email_and_password('test@example.com', 'testing')
          #   # results in a call to
          #   User.find_by_encrypted_email_and_password('the_encrypted_version_of_test@example.com', 'testing')
          def method_missing_with_attr_encrypted(method, *args, &block)
            if match = /^(find|scoped)_(all_by|by)_([_a-zA-Z]\w*)$/.match(method.to_s)
              attribute_names = match.captures.last.split('_and_')
              attribute_names.each_with_index do |attribute, index|
                if attr_encrypted?(attribute)
                  args[index] = send("encrypt_#{attribute}", args[index])
                  attribute_names[index] = encrypted_attributes[attribute.to_sym][:attribute]
                end
              end
              method = "#{match.captures[0]}_#{match.captures[1]}_#{attribute_names.join('_and_')}".to_sym
            end
            method_missing_without_attr_encrypted(method, *args, &block)
          end

          # Saves the attr class wrappers, so AR can infer the correct type later
          def encrypted_attribute_class_wrappers
            @encrypted_attribute_class_wrappers ||= {}
          end

          # Allows AR to infer the proper type for the column
          class EncryptedAttributeClassWrapper
            attr_reader :klass
            def initialize(klass); @klass = klass; end
          end

      end
    end
  end

  class ActiveRecord::Base
    # Patch column_for_attribute so we can infer the correct column type
    alias_method :column_for_attribute_base, :column_for_attribute
    def column_for_attribute(attribute)
      attribute_sym = attribute.to_sym
      if encrypted = self.class.encrypted_attributes[attribute_sym]
        column_info = self.class.send(:encrypted_attribute_class_wrappers)[attribute_sym]
        column_info ||= column_for_attribute_base(encrypted[:attribute])
        column_info
      else
        column_for_attribute_base(attribute)
      end
    end
  end
  ActiveRecord::Base.extend AttrEncrypted::Adapters::ActiveRecord
end