if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        
        module ARMethods

          # https://github.com/attr-encrypted/attr_encrypted/issues/68
          def reload(*args, &block)
            result = super
            self.class.encrypted_attributes.keys.each do |attribute_name|
              instance_variable_set("@#{attribute_name}", nil)
            end
            result
          end
          
          def attributes=(attributes, *args)
            return if attributes.blank?
            super (attributes.reject { |k, _|  self.class.encrypted_attributes.key?(k.to_sym) }), *args
            super (attributes.reject { |k, _| !self.class.encrypted_attributes.key?(k.to_sym) }), *args
          end
                  
        end
        
        
        module ARMethodMissing
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
          def method_missing(method, *args, &block)
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
            super(method, *args, &block)
          end
        end
        
              
        def self.extended(base) # :nodoc:
          base.class_eval do
            prepend ARMethods
            attr_encrypted_options[:encode] = true

            class << self
              prepend ARMethodMissing
            end
          end
        end

        protected

          # <tt>attr_encrypted</tt> method
          def attr_encrypted(*attrs)
            super
            options = attrs.extract_options!
            attr = attrs.pop
            options.merge! encrypted_attributes[attr]

            define_method("#{attr}_changed?") do
              if send("#{options[:attribute]}_changed?")
                send(attr) != send("#{attr}_was")
              end
            end

            define_method("#{attr}_was") do
              attr_was_options = { operation: :decrypting }
              attr_was_options[:iv]= send("#{options[:attribute]}_iv_was") if respond_to?("#{options[:attribute]}_iv_was")
              attr_was_options[:salt]= send("#{options[:attribute]}_salt_was") if respond_to?("#{options[:attribute]}_salt_was")
              encrypted_attributes[attr].merge!(attr_was_options)
              evaluated_options = evaluated_attr_encrypted_options_for(attr)
              [:iv, :salt, :operation].each { |key| encrypted_attributes[attr].delete(key) }
              self.class.decrypt(attr, send("#{options[:attribute]}_was"), evaluated_options)
            end

            alias_method "#{attr}_before_type_cast", attr
          end

          def attribute_instance_methods_as_symbols
            # We add accessor methods of the db columns to the list of instance
            # methods returned to let ActiveRecord define the accessor methods
            # for the db columns

            # Use with_connection so the connection doesn't stay pinned to the thread.
            connected = ::ActiveRecord::Base.connection_pool.with_connection(&:active?) rescue false

            if connected && table_exists?
              columns_hash.keys.inject(super) {|instance_methods, column_name| instance_methods.concat [column_name.to_sym, :"#{column_name}="]}
            else
              super
            end
          end


      end
    end
  end

  ActiveRecord::Base.extend AttrEncrypted
  ActiveRecord::Base.extend AttrEncrypted::Adapters::ActiveRecord
end
