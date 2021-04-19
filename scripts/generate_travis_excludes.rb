#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'

class String
  def versionish?
    ::Gem::Version.correct?(self)
  end
end

class Numeric
  def versionish?
    true
  end
end

TRAVIS_TEMPLATE_PATH = File.expand_path('../.travis.base.yml', __dir__)
TRAVIS_CONFIG_PATH = File.expand_path('../.travis.yml', __dir__)

GEMFILE_RUBY_VERSIONS = {
  'gemfiles/rails_3.0.gemfile':    '< 2.4',
  'gemfiles/rails_3.1.gemfile':    '< 2.4',
  'gemfiles/rails_3.2.gemfile':    '< 2.4',
  'gemfiles/rails_4.0.gemfile':    '< 2.4',
  'gemfiles/rails_4.1.gemfile':    '< 2.4',
  # apparently supports up to at least ruby 2.5
  'gemfiles/rails_4.2.gemfile':    '>= 0',
  'gemfiles/rails_5.0.gemfile':    '>= 2.2',
  'gemfiles/rails_5.1.gemfile':    '>= 2.2',
  'gemfiles/rails_5.2.gemfile':    '>= 2.5',
  'gemfiles/rails_6.0.gemfile':    '>= 2.5',
  'gemfiles/rails_6.1.gemfile':    '>= 2.5',
  'gemfiles/rails_7_edge.gemfile': '>= 2.5',
  #'gemfiles/datamapper.gemfile':   '>= 0',
  #'gemfiles/sequel.gemfile':       '>= 0',
}.transform_values { |ver| Gem::Requirement.create(ver.to_s) }

GEMFILE_FAILABLE_RUBY_VERSIONS = {
  'gemfiles/rails_4.2.gemfile':   '>= 2.5',
}.transform_values { |ver| Gem::Requirement.create(ver.to_s) }

TREAT_RUBY_HEAD_AS = Gem::Version.new('3.1')

travis_config = YAML.load_file(TRAVIS_TEMPLATE_PATH)

ruby_versions = travis_config['rvm'].select(&:versionish?).map { |ver| Gem::Version.new(ver) }
ruby_versions << TREAT_RUBY_HEAD_AS

travis_config['jobs'] ||= {}
excludes  = (travis_config['jobs']['exclude'] ||= [])
failables = (travis_config['jobs']['allow_failures'] ||= [])

requirement_combinations = GEMFILE_RUBY_VERSIONS.to_a.product(ruby_versions)
failable_combinations    = GEMFILE_FAILABLE_RUBY_VERSIONS.to_a.product(ruby_versions)

requirement_combinations.each do |((gemfile, constraint), ruby_ver)|
  next if constraint.satisfied_by?(ruby_ver)

  rvm = ruby_ver == TREAT_RUBY_HEAD_AS ? 'head' : ruby_ver.to_s
  excludes << {
    'gemfile' => gemfile.to_s,
    'rvm'     => rvm
  }
end

failable_combinations.each do |((gemfile, constraint), ruby_ver)|
  next if constraint.satisfied_by?(ruby_ver)

  rvm = ruby_ver == TREAT_RUBY_HEAD_AS ? 'head' : ruby_ver.to_s
  failables << {
    'gemfile' => gemfile.to_s,
    'rvm'     => rvm
  }
end

File.open TRAVIS_CONFIG_PATH, 'wt' do |f|
  YAML.dump(travis_config, f)
end

printf "Done. (%d excludes and %d allowed failures)\n", excludes.size, failables.size
