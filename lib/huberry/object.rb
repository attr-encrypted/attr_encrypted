module Huberry
  module Object
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        cattr_accessor :attr_encrypted_options, :encrypted_attributes
        self.attr_encrypted_options = {}
        self.encrypted_attributes = {}
      end
    end
    
    def read_attribute(attribute)
      instance_variable_get("@#{attribute}")
    end
    
    def write_attribute(attribute, value)
      instance_variable_set("@#{attribute}", value)
    end
    
    module ClassMethods
      def attr_encrypted?(attribute)
        encrypted_attributes.keys.include?(attribute.to_s)
      end
      
      def inherited(base)
        base.attr_encrypted_options = self.attr_encrypted_options.nil? ? {} : self.attr_encrypted_options.dup
        base.encrypted_attributes = self.encrypted_attributes.nil? ? {} : self.encrypted_attributes.dup
      end
    end
  end
end