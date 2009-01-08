module Huberry
  module Object
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        eattr_accessor :attr_encrypted_options, :encrypted_attributes
        attr_encrypted_options = {}
        encrypted_attributes = {}
      end
    end
    
    # Wraps instance_variable_get
    def read_attribute(attribute)
      instance_variable_get("@#{attribute}")
    end
    
    # Wraps instance_variable_set
    def write_attribute(attribute, value)
      instance_variable_set("@#{attribute}", value)
    end
    
    module ClassMethods
      # Checks if an attribute has been configured to be encrypted
      #
      # Example
      #
      #   class User
      #     attr_accessor :name
      #     attr_encrypted :email
      #   end
      #
      #   User.attr_encrypted?(:name) # false
      #   User.attr_encrypted?(:email) # true
      def attr_encrypted?(attribute)
        encrypted_attributes.keys.include?(attribute.to_s)
      end
      
      # Copies existing encrypted attributes and options to the derived class
      def inherited(base)
        base.attr_encrypted_options = self.attr_encrypted_options.nil? ? {} : self.attr_encrypted_options.dup
        base.encrypted_attributes = self.encrypted_attributes.nil? ? {} : self.encrypted_attributes.dup
      end
    end
  end
end