if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        def self.extended(base) # :nodoc:
          base.class_eval do
            attr_encrypted_options[:encode] = true
            class << self; alias_method_chain :method_missing, :attr_encrypted; end

            def assign_attributes_with_attr_encrypted(*args)
              attributes = args.shift
              encrypted_attributes = self.class.encrypted_attributes.keys
              assign_attributes_without_attr_encrypted attributes.except(*encrypted_attributes), *args
              assign_attributes_without_attr_encrypted attributes.slice(*encrypted_attributes), *args
            end
            alias_method_chain :assign_attributes, :attr_encrypted
          end
        end

        protected

          # Ensures the attribute methods for db fields have been defined before calling the original 
          # <tt>attr_encrypted</tt> method
          def attr_encrypted(*attrs)
            define_attribute_methods rescue nil
            super
            undefine_attribute_methods
            attrs.reject { |attr| attr.is_a?(Hash) }.each { |attr|
              alias_method "#{attr}_before_type_cast", attr
              # Simulate ActiveRecord dirty methods
              encrypted_attr = encrypted_attributes[attr.to_sym][:attribute]
              class_eval <<-EOS
              def #{attr}_was
                #{encrypted_attr}_was.nil? ? nil : decrypt(:#{attr}, #{encrypted_attr}_was)
              end
              def #{attr}_change
                [#{attr}_was, __send__(:#{attr})] if #{encrypted_attr}_changed?
              end
              def #{attr}_changed?
                #{encrypted_attr}_changed?
              end
              EOS
            }
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
      end
    end
  end

  ActiveRecord::Base.extend AttrEncrypted::Adapters::ActiveRecord
end
