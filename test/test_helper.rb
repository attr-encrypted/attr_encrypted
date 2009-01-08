require 'test/unit'
require 'digest/sha2'

require 'rubygems'
gem 'shuber-eigenclass', '>= 1.0.1'
gem 'shuber-encryptor'
gem 'activerecord'
gem 'datamapper'

require 'eigenclass'
require 'encryptor'
require 'active_record'
require 'datamapper'

require File.dirname(__FILE__) + '/../lib/attr_encrypted'