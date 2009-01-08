require 'test/unit'
require 'digest/sha2'

require 'rubygems'
gem 'shuber-eigenclass'
gem 'shuber-encryptor'
gem 'activerecord'

require 'eigenclass'
require 'encryptor'
require 'active_record'

require File.dirname(__FILE__) + '/../lib/attr_encrypted'