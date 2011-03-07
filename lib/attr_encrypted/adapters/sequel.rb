if defined?(Sequel)
  module AttrEncrypted
    module Adapters
      module Sequel
        def self.extended(base)
          base.attr_encrypted_options[:encode] = true
        end
      end
    end
  end

  Sequel::Model.extend AttrEncrypted::Adapters::Sequel
end