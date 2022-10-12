# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'attr_encrypted/version'
require 'date'

Gem::Specification.new do |s|
  s.name    = 'attr_encrypted'
  s.version = AttrEncrypted::Version.string
  s.date    = Date.today

  s.summary     = 'Encrypt and decrypt attributes'
  s.description = 'Generates attr_accessors that encrypt and decrypt attributes transparently'

  s.authors   = ['Sean Huber', 'S. Brent Faulkner', 'William Monk', 'Stephen Aghaulor']
  s.email    = ['seah@shuber.io', 'sbfaulkner@gmail.com', 'billy.monk@gmail.com', 'saghaulor@gmail.com']
  s.homepage = 'http://github.com/attr-encrypted/attr_encrypted'
  s.license = 'MIT'

  s.rdoc_options = ['--line-numbers', '--inline-source', '--main', 'README.rdoc']

  s.require_paths = ['lib']

  s.files      = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency('encryptor', ['~> 3.0.0'])
  # support for testing with specific active record version
  activerecord_version = if ENV.key?('ACTIVERECORD')
    "~> #{ENV['ACTIVERECORD']}"
  else
    '>= 2.0.0'
  end
  s.add_development_dependency('activerecord', activerecord_version)
  s.add_development_dependency('actionpack', activerecord_version)
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('sequel')
  s.add_development_dependency('pry-byebug')
  if RUBY_VERSION < '2.1.0'
    s.add_development_dependency('nokogiri', '< 1.7.0')
    s.add_development_dependency('public_suffix', '< 3.0.0')
  end
  if defined?(RUBY_ENGINE) && RUBY_ENGINE.to_sym == :jruby
    s.add_development_dependency('activerecord-jdbcsqlite3-adapter')
    s.add_development_dependency('jdbc-sqlite3', '< 3.8.7') # 3.8.7 is nice and broke
  else
    s.add_development_dependency('sqlite3', '~> 1.4.0', '>= 1.4')
  end
  s.add_development_dependency('simplecov')
  s.add_development_dependency('simplecov-rcov')
  s.add_development_dependency("codeclimate-test-reporter", '<= 0.6.0')

  s.cert_chain  = ['certs/saghaulor.pem']
  s.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/
end
