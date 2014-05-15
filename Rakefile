require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Test the attr_encrypted gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
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

if RUBY_VERSION < '1.9.3'
  require 'rcov/rcovtask'

  task :rcov do
    sh "rcov -o coverage/rcov --exclude '^(?!lib)' " + FileList[ 'test/**/*_test.rb' ].join(' ')
  end

  desc 'Default: run unit tests under rcov.'
  task :default => :rcov
else
  desc 'Default: run unit tests.'
  task :default => :test
end
