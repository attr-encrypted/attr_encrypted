require 'rails/railtie'

module AttrEncrypted
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      Object.extend AttrEncrypted

      Dir[File.join(File.dirname(__FILE__), 'attr_encrypted', 'adapters', '*.rb')].each { |adapter| require adapter }
    end
  end
end
