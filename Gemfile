source 'https://rubygems.org'

gemspec

gem 'sqlite3'

if RUBY_VERSION < '2.1.0'
  gem 'nokogiri'
  gem 'public_suffix', '< 3.0.0'
end

platforms :jruby do
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3', '< 3.8.7' # 3.8.7 is nice and broke
end

group :development do
  gem 'wwtd',    require: false
  gem 'rubocop', require: false
end
