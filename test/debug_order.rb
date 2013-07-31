require 'digest/sha2'
require 'rubygems'
gem 'activerecord', ENV['ACTIVE_RECORD_VERSION'] if ENV['ACTIVE_RECORD_VERSION']
require 'active_record'
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'attr_encrypted'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_tables
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :accounts do |t|
        t.string :encrypted_password
        t.string :encrypted_password_iv
        t.string :encrypted_password_salt
      end
    end
  end
end

# The table needs to exist before defining the class
create_tables
require 'ruby-debug'
require 'pry'
class Account < ActiveRecord::Base
  self.attr_encrypted_options[:mode] = :per_attribute_iv_and_salt

  attr_accessor :key
  attr_encrypted :password, :key => Proc.new {|account| binding.pry}
end

def setup
  ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
  create_tables
end
setup
require 'ruby-debug'
binding.pry

Account.create!(:password => "password" , :key => "secret")

