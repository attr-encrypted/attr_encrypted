require 'rails/railtie'

module AttrEncrypted
  class Railtie < ::Rails::Railtie
    initializer "attr_encrypted.active_record", :after => "active_record.set_configs" do |app|
      Object.extend AttrEncrypted

      Dir[File.join(File.dirname(__FILE__), 'attr_encrypted', 'adapters', '*.rb')].each { |adapter| require adapter }
    end
  end
end
