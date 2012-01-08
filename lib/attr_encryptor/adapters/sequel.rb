if defined?(Sequel)
  module AttrEncryptor
    module Adapters
      module Sequel
        def self.extended(base) # :nodoc:
          base.attr_encrypted_options[:encode] = true
        end
      end
    end
  end

  Sequel::Model.extend AttrEncryptor::Adapters::Sequel

end
