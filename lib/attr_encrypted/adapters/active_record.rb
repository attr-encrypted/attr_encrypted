# frozen_string_literal: true

if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        def self.extended(base) # :nodoc:
          base.class_eval do

            # https://github.com/attr-encrypted/attr_encrypted/issues/68
            alias_method :reload_without_attr_encrypted, :reload
            def reload(*args, &block)
              result = reload_without_attr_encrypted(*args, &block)
              self.class.attr_encrypted_attributes.keys.each do |attribute_name|
                instance_variable_set("@#{attribute_name}", nil)
              end
              result
            end

            attr_encrypted_options[:encode] = true

            class << self
              alias_method :method_missing_without_attr_encrypted, :method_missing
            end

            def perform_attribute_assignment(method, new_attributes, *args)
              return if new_attributes.blank?

              send method, new_attributes.reject { |k, _|  self.class.attr_encrypted_attributes.key?(k.to_sym) }, *args
              send method, new_attributes.reject { |k, _| !self.class.attr_encrypted_attributes.key?(k.to_sym) }, *args
            end
            private :perform_attribute_assignment

            alias_method :assign_attributes_without_attr_encrypted, :assign_attributes
            def assign_attributes(*args)
              perform_attribute_assignment :assign_attributes_without_attr_encrypted, *args
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
            options.merge! attr_encrypted_attributes[attr]

            define_method("#{attr}_changed?") do |options = {}|
              attribute_changed?(attr, **options)
            end

            define_method("#{attr}_with_dirtiness=") do |value|
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
      end
    end
  end

  ActiveSupport.on_load(:active_record) do
    extend AttrEncrypted
    extend AttrEncrypted::Adapters::ActiveRecord
  end
end
