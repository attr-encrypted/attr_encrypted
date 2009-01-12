if defined?(Sequel)
  module Huberry
    module AttrEncrypted
      module Adapters
        module Sequel
          def self.extended(base)
            base.attr_encrypted_options.merge!(:encode => true, :marshal => true)
          end
        end
      end
    end
  end
  
  Sequel::Model.extend Huberry::AttrEncrypted::Adapters::Sequel
end