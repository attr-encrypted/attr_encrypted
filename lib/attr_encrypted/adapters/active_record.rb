# frozen_string_literal: true

if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        RAILS_VERSION = Gem::Version.new(::ActiveRecord::VERSION::STRING).freeze

        def self.extended(base) # :nodoc:
          base.class_eval do

            # https://github.com/attr-encrypted/attr_encrypted/issues/68
            alias_method :reload_without_attr_encrypted, :reload
            def reload(*args, &block)
              result = reload_without_attr_encrypted(*args, &block)
              self.class.attr_encrypted_encrypted_attributes.keys.each do |attribute_name|
                instance_variable_set("@#{attribute_name}", nil)
              end
              result
            end

            attr_encrypted_options[:encode] = true

            class << self
              alias_method :method_missing_without_attr_encrypted, :method_missing
              alias_method :method_missing, :method_missing_with_attr_encrypted
            end

            def perform_attribute_assignment(method, new_attributes, *args)
              return if new_attributes.blank?

              send method, new_attributes.reject { |k, _|  self.class.attr_encrypted_encrypted_attributes.key?(k.to_sym) }, *args
              send method, new_attributes.reject { |k, _| !self.class.attr_encrypted_encrypted_attributes.key?(k.to_sym) }, *args
            end
            private :perform_attribute_assignment

            if Gem::Requirement.new('> 3.1').satisfied_by?(RAILS_VERSION)
              alias_method :assign_attributes_without_attr_encrypted, :assign_attributes
              def assign_attributes(*args)
                perform_attribute_assignment :assign_attributes_without_attr_encrypted, *args
              end
            end

            alias_method :attributes_without_attr_encrypted=, :attributes=
            def attributes=(*args)
              perform_attribute_assignment :attributes_without_attr_encrypted=, *args
            end
          end
        end

        protected

          # <tt>attr_encrypted</tt> method
          def attr_encrypted(*attrs)
            super
            options = attrs.extract_options!
            attr = attrs.pop
            attribute attr
            options.merge! attr_encrypted_encrypted_attributes[attr]

            define_method("#{attr}_was") do
              attribute_was(attr)
            end

            define_method("#{attr}_changed?") do |options = {}|
              attribute_changed?(attr, **options)
            end

            define_method("#{attr}_change") do
              attribute_change(attr)
            end

            define_method("#{attr}_with_dirtiness=") do |value|
              ## Source: https://github.com/priyankatapar/attr_encrypted/commit/7e8702bd5418c927a39d8dd72c0adbea522d5663
              # In ActiveRecord 5.2+, due to changes to the way virtual
              # attributes are handled, @attributes[attr].value is nil which
              # breaks attribute_was. Setting it here returns us to the expected
              # behavior.
              if Gem::Requirement.new('>= 5.2').satisfied_by?(RAILS_VERSION)
                # This is needed support attribute_was before a record has
                # been saved
                set_attribute_was(attr, __send__(attr)) if value != __send__(attr)
                # This is needed to support attribute_was after a record has
                # been saved
                @attributes.write_from_user(attr.to_s, value) if value != __send__(attr)
              end
              attribute_will_change!(attr) if value != __send__(attr)
              __send__("#{attr}_without_dirtiness=", value)
            end

            alias_method "#{attr}_without_dirtiness=", "#{attr}="
            alias_method "#{attr}=", "#{attr}_with_dirtiness="

            alias_method "#{attr}_before_type_cast", attr
          end

          def attribute_instance_methods_as_symbols
            # We add accessor methods of the db columns to the list of instance
            # methods returned to let ActiveRecord define the accessor methods
            # for the db columns

            if connected? && table_exists?
              columns_hash.keys.inject(super) {|instance_methods, column_name| instance_methods.concat [column_name.to_sym, :"#{column_name}="]}
            else
              super
            end
          end

          def attribute_instance_methods_as_symbols_available?
            connected? && table_exists?
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
                if attr_encrypted?(attribute) && attr_encrypted_encrypted_attributes[attribute.to_sym][:mode] == :single_iv_and_salt
                  args[index] = send("encrypt_#{attribute}", args[index])
                  warn "DEPRECATION WARNING: This feature will be removed in the next major release."
                  attribute_names[index] = attr_encrypted_encrypted_attributes[attribute.to_sym][:attribute]
                end
              end
              method = "#{match.captures[0]}_#{match.captures[1]}_#{attribute_names.join('_and_')}".to_sym
            end
            method_missing_without_attr_encrypted(method, *args, &block)
          end
      end
    end
  end

  ActiveSupport.on_load(:active_record) do
    extend AttrEncrypted
    extend AttrEncrypted::Adapters::ActiveRecord
  end
end
