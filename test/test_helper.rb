require 'test/unit'
require 'digest/sha2'
require 'rubygems'
gem 'activerecord', ENV['ACTIVE_RECORD_VERSION'] if ENV['ACTIVE_RECORD_VERSION']
require 'active_record'
require 'data_mapper'
require 'sequel'
require 'mocha'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'attr_encryptor'

puts "\nTesting with ActiveRecord #{ActiveRecord::VERSION::STRING rescue ENV['ACTIVE_RECORD_VERSION']}"
