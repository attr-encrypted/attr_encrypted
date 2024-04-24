# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'attr_encrypted/version'
require 'date'

Gem::Specification.new do |s|
  s.name    = 'powerhome-attr_encrypted'
  s.version = AttrEncrypted::Version.string
  s.date    = Date.today

  s.summary     = "Power's version of the attr_encrypted gem"
  s.description = 'Generates attr_accessors that encrypt and decrypt attributes transparently'

  s.authors   = ['Wade Winningham', 'Ben Langfeld']
  s.email    = ['wwinningham@powerhrg.com', 'ben@langfeld.me']
  s.homepage = 'https://github.com/powerhome/attr_encrypted'
  s.license = 'MIT'

  s.require_paths = ['lib']

  s.files      = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")

  s.required_ruby_version = '>= 2.6.0'

  s.add_dependency('encryptor', ['~> 3.0.0'])
  # support for testing with specific active record version
  activerecord_version = if ENV.key?('ACTIVERECORD')
    "~> #{ENV['ACTIVERECORD']}.0"
  else
    '>= 2.0.0'
  end
  s.add_development_dependency('activerecord', activerecord_version)
  s.add_development_dependency('actionpack', activerecord_version)
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('sequel')

  if defined?(RUBY_ENGINE) && RUBY_ENGINE.to_sym == :jruby
    s.add_development_dependency('activerecord-jdbcsqlite3-adapter')
    s.add_development_dependency('jdbc-sqlite3', '< 3.8.7') # 3.8.7 is nice and broke
  else
    s.add_development_dependency('sqlite3', '= 1.5.4')
  end
  s.add_development_dependency('dm-sqlite-adapter')
  s.add_development_dependency('pry')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('simplecov-rcov')

  s.post_install_message = "\n\n\nWARNING: Using `#encrypted_attributes` is no longer supported. Instead, use `#attr_encrypted_encrypted_attributes` to avoid
  collision with Active Record 7 native encryption.\n\n\n"

end
