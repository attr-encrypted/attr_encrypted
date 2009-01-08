module Huberry
  module ActiveRecord
    def self.extended(base)
      base.alias_method_chain :method_missing, :attr_encrypted
    end
    
    protected
    
      # Calls attr_encrypted with the options <tt>:encode</tt> and <tt>:marshal</tt> set to true
      # unless they've already been specified
      def attr_encrypted(*attrs)
        options = { :encode => true, :marshal => true }.merge(attrs.last.is_a?(Hash) ? attrs.pop : {})
        super *(attrs << options)
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