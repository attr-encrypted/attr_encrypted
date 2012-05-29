require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the attr_encrypted gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  # t.pattern = 'test/**/*_test.rb'
  t.pattern = ENV['TEST'] ? ENV['TEST'] : 'test/**/*_test.rb'
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