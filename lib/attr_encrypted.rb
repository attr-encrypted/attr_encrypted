require 'huberry/class'
Class.send :include, Huberry::Class

require 'huberry/object'
Object.send :include, Huberry::Object

if defined?(ActiveRecord)
  require 'huberry/active_record'
  ActiveRecord::Base.extend Huberry::ActiveRecord
end