module Huberry
  module AttrEncrypted
    module Object
      def self.extended(base)
        base.attr_encrypted_options = {}
        base.instance_variable_set('@encrypted_attributes', {})
      end
      
      # Default options to use with calls to <tt>attr_encrypted</tt>.
      #
      # It will inherit existing options from its parent class
      def attr_encrypted_options
        @attr_encrypted_options ||= superclass.attr_encrypted_options.nil? ? {} : superclass.attr_encrypted_options.dup
      end
      
      # Sets default options to use with calls to <tt>attr_encrypted</tt>.
      def attr_encrypted_options=(options)
        @attr_encrypted_options = options
      end
      
      # Contains a hash of encrypted attributes with virtual attribute names as keys and real attribute 
      # names as values
      #
      # Example
      #
      #   class User
      #     attr_encrypted :email
      #   end
      #
      #   User.encrypted_attributes # { 'email' => 'encrypted_email' }
      def encrypted_attributes
        @encrypted_attributes ||= superclass.encrypted_attributes.nil? ? {} : superclass.encrypted_attributes.dup
      end
      
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
    end
  end
end