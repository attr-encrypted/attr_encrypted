if defined?(ActiveRecord::Base)
  module AttrEncryptor
    module Adapters
      module ActiveRecord
        def self.extended(base) # :nodoc:
          base.class_eval do
            attr_encrypted_options[:encode] = true
          end
        end

        protected

          # Ensures the attribute methods for db fields have been defined before calling the original 
          # <tt>attr_encrypted</tt> method
          def attr_encrypted(*attrs)
            define_attribute_methods rescue nil
            super
            attrs.reject { |attr| attr.is_a?(Hash) }.each { |attr| alias_method "#{attr}_before_type_cast", attr }
          end
      end
    end
  end

  ActiveRecord::Base.extend AttrEncryptor::Adapters::ActiveRecord
end
