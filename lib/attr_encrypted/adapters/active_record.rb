if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        def self.extended(base) # :nodoc:
          base.class_eval do
            class << self
              alias_method_chain :attr_encrypted, :defined_attributes
              alias_method_chain :attr_encryptor, :defined_attributes
            end
            
            attr_encrypted_options[:encode] = true
          end
        end

        protected

        # Ensures the attribute methods for db fields have been defined before calling the original 
        # <tt>attr_encrypted</tt> method
        def attr_encrypted_with_defined_attributes(*attrs)
          define_attribute_methods rescue nil
          attr_encrypted_without_defined_attributes *attrs
          attrs.reject { |attr| attr.is_a?(Hash) }.each { |attr| alias_method "#{attr}_before_type_cast", attr }
        end
        
        alias attr_encryptor_with_defined_attributes attr_encrypted_with_defined_attributes
      end
    end
  end

  ActiveRecord::Base.extend AttrEncrypted::Adapters::ActiveRecord
end
