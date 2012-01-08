# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'attr_encryptor/version'
require 'date'

Gem::Specification.new do |s|
  s.name    = 'attr_encryptor'
  s.version = AttrEncryptor::Version.string
  s.date    = Date.today

  s.summary     = 'Encrypt and decrypt attributes'
  s.description = 'Generates attr_accessors that encrypt and decrypt attributes transparently'

  s.author   = 'Daniel Palacio'
  s.email    = 'danpal@gmail.com'
  s.homepage = 'http://github.com/danpal/attr_encrypted'

  s.has_rdoc = false
  s.rdoc_options = ['--line-numbers', '--inline-source', '--main', 'README.rdoc']

  s.require_paths = ['lib']
  
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_dependency('encryptor2', ['>= 1.0.0'])
  s.add_development_dependency('activerecord', ['>= 2.0.0'])
  s.add_development_dependency('datamapper')
  s.add_development_dependency('mocha')
  s.add_development_dependency('sequel')
  s.add_development_dependency('dm-sqlite-adapter')
  s.add_development_dependency('sqlite3')
end
