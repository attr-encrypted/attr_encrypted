source "http://rubygems.org"

gem 'encryptor', :git => 'https://github.com/attr-encrypted/encryptor'

gemspec

# support for testing with specific active record version
gem 'activerecord', "~> #{ENV['ACTIVERECORD']}" if ENV['ACTIVERECORD']
gem 'actionpack', "~> 4.0.0" if ENV['ACTIVERECORD'] && ENV['ACTIVERECORD'] > '4.0'
