module Huberry
  module Class    
    protected
      def attr_encrypted(*attrs)
        options = { 
          :prefix => 'encrypted_', 
          :suffix => '', 
          :encryptor => Huberry::Encryptor, 
          :encrypt_method => :encrypt,
          :decrypt_method => :decrypt,
          :encode => false, 
          :marshal => false 
        }.merge(attr_encrypted_options).merge(attrs.last.is_a?(Hash) ? attrs.pop : {})
      
        attrs.each do |attribute|
          encrypted_attribute_name = options[:attribute].nil? ? options[:prefix].to_s + attribute.to_s + options[:suffix].to_s : options[:attribute].to_s
          
          encrypted_attributes[attribute.to_s] = encrypted_attribute_name
        
          attr_accessor encrypted_attribute_name.to_sym unless self.new.respond_to?(encrypted_attribute_name)
        
          define_class_method "encrypt_#{attribute}" do |value|
            if value.nil?
              encrypted_value = nil
            else
              value = Marshal.dump(value) if options[:marshal]
              encrypted_value = options[:encryptor].send options[:encrypt_method], options.merge(:value => value)
              encrypted_value = [encrypted_value].pack('m*') if options[:encode]
            end
            encrypted_value
          end
          
          define_class_method "decrypt_#{attribute}" do |encrypted_value|
            if encrypted_value.nil?
              decrypted_value = nil
            else
              encrypted_value = encrypted_value.unpack('m*').to_s if options[:encode]
              decrypted_value = options[:encryptor].send(options[:decrypt_method], options.merge(:value => encrypted_value))
              decrypted_value = Marshal.load(decrypted_value) if options[:marshal]
            end
            decrypted_value
          end
        
          define_method "#{attribute}" do
            value = instance_variable_get("@#{attribute}")
            encrypted_value = read_attribute(encrypted_attribute_name)
            original_key = options[:key]
            options[:key] = self.class.send :evaluate_attr_encrypted_key, options[:key], self
            value = write_attribute(attribute, self.class.send("decrypt_#{attribute}".to_sym, encrypted_value)) if value.nil? && !encrypted_value.nil?
            options[:key] = original_key
            value
          end
        
          define_method "#{attribute}=" do |value|
            original_key = options[:key]
            options[:key] = self.class.send :evaluate_attr_encrypted_key, options[:key], self
            write_attribute(encrypted_attribute_name, self.class.send("encrypt_#{attribute}".to_sym, value))
            options[:key] = original_key
            instance_variable_set("@#{attribute}", value)
          end
        end
      end
      
      # Evaluates encryption keys specified as symbols (representing instance methods) or procs
      # If the key is not a symbol or proc then the original key is returned
      def evaluate_attr_encrypted_key(key, object)
        case key
        when Symbol
          object.send(key)
        when Proc
          key.call(object)
        else
          key
        end
      end
  end
end