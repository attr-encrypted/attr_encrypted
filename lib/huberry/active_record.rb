module Huberry
  module ActiveRecord
    def self.extended(base)
      base.alias_method_chain :method_missing, :attr_encrypted
    end
    
    protected
    
      def attr_encrypted(*attrs)
        options = { :encode => true, :marshal => true }.merge(attrs.last.is_a?(Hash) ? attrs.pop : {})
        super *(attrs << options)
      end
    
      def method_missing_with_attr_encrypted(method, *args, &block)
        if match = /^(find|scoped)_(all_by|by)_([_a-zA-Z]\w*)$/.match(method.to_s)
          attribute_names = extract_attribute_names_from_match(match)
          attribute_names.each_with_index do |attribute, index|
            if attr_encrypted?(attribute)
              args[index] = send("encrypt_#{attribute}", args[index])
              attribute_names[index] = encrypted_attributes[attribute]
            end
          end
          method = "#{$1}_#{$2}_#{attribute_names.join('_and_')}".to_sym
        end
        method_missing_without_attr_encrypted(method, *args, &block)
      end
  end
end