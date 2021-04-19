# frozen_string_literal: true

require 'rake/testtask'
require 'rdoc/task'
require "bundler/gem_tasks"
require 'wwtd/tasks'

desc 'Test the attr_encrypted gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
  t.verbose = true
end

desc 'Generate documentation for the attr_encrypted gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'attr_encrypted'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Default: run unit tests.'
if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  task :default => :appraisal
end
#task :default => :test
