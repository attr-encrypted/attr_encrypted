if defined?(DataMapper)
  module Huberry
    module AttrEncrypted
      module Adapters
        module DataMapper
          def self.extended(base)
            base.eigenclass_eval do 
              alias_method :included_without_attr_encrypted, :included
              alias_method :included, :included_with_attr_encrypted
            end
          end
          
          def included_with_attr_encrypted(base)
            included_without_attr_encrypted(base)
            base.attr_encrypted_options[:encode] = true
          end
        end
      end
    end
  end
  
  DataMapper::Resource.extend Huberry::AttrEncrypted::Adapters::DataMapper
end