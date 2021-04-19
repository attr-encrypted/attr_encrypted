# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'attr_encrypted/version'
require 'date'

Gem::Specification.new do |s|
  s.name        = 'attr_encrypted'
  s.version     = AttrEncrypted::Version.string

  s.summary     = 'Encrypt and decrypt attributes'
  s.description = 'Generates attr_accessors that encrypt and decrypt attributes transparently'

  s.authors     = ['Mike Vastola', 'Rob Law', 'Sean Huber', 'S. Brent Faulkner', 'William Monk', 'Stephen Aghaulor']
  s.email       = ['open-source@dailypay.com']
  s.license     = 'MIT'

  s.metadata = {
    'homepage_uri'      => "https://github.com/attr-encrypted/attr_encrypted",
    'source_code_uri'   => "https://github.com/attr-encrypted/attr_encrypted",
    'changelog_uri'     => "https://github.com/attr-encrypted/attr_encrypted/blob/master/CHANGELOG.md",
    'bug_tracker_uri'   => "https://github.com/attr-encrypted/attr_encrypted/issues",
    'documentation_uri' => "https://rubydoc.info/gems/attr_encrypted",
    'wiki_uri'          => "https://github.com/attr-encrypted/attr_encrypted/wiki",
  }

  s.rdoc_options     = %w[--line-numbers --inline-source --main README.rdoc]
  s.extra_rdoc_files = %w[README.md]
  s.require_paths    = ['lib']

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- test/*`.split("\n")

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency             'encryptor',    '~> 3.0.0'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'codeclimate-test-reporter', '<= 0.6.0'

  s.cert_chain  = %w[certs/saghaulor.pem]
  s.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/

  s.post_install_message = "\n\n\nWARNING: Several insecure default options and features were deprecated in attr_encrypted v2.0.0.\n
Additionally, there was a bug in Encryptor v2.0.0 that insecurely encrypted data when using an AES-*-GCM algorithm.\n
This bug was fixed but introduced breaking changes between v2.x and v3.x.\n
Please see the README for more information regarding upgrading to attr_encrypted v3.0.0.\n\n\n"
end
