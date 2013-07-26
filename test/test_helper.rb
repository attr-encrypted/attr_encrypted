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
require 'attr_encrypted'

puts "\nTesting with ActiveRecord #{ActiveRecord::VERSION::STRING rescue ENV['ACTIVE_RECORD_VERSION']}"

DB = Sequel.sqlite

# The :after_initialize hook was removed in Sequel 4.0
# and had been deprecated for a while before that:
# http://sequel.rubyforge.org/rdoc-plugins/classes/Sequel/Plugins/AfterInitialize.html
# This plugin re-enables it.
Sequel::Model.plugin :after_initialize

SECRET_KEY = 4.times.map { Digest::SHA256.hexdigest((Time.now.to_i * rand(5)).to_s) }.join

