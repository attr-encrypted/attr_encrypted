require 'huberry/attr_encrypted/class'
Class.send :include, Huberry::AttrEncrypted::Class

require 'huberry/attr_encrypted/object'
Object.extend Huberry::AttrEncrypted::Object

if defined?(ActiveRecord)
  require 'huberry/attr_encrypted/active_record'
  ActiveRecord::Base.extend Huberry::AttrEncrypted::ActiveRecord
end

if defined?(DataMapper)
  require 'huberry/attr_encrypted/data_mapper'
  DataMapper::Resource.send :include, Huberry::AttrEncrypted::DataMapper
end