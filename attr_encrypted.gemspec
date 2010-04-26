Gem::Specification.new do |s| 
  s.name    = 'attr_encrypted'
  s.version = '1.1.2'
  s.date    = '2010-04-26'
  
  s.summary     = 'Generates attr_accessors that encrypt and decrypt attributes transparently'
  s.description = 'Generates attr_accessors that encrypt and decrypt attributes transparently'
  
  s.author   = 'Sean Huber'
  s.email    = 'shuber@huberry.com'
  s.homepage = 'http://github.com/shuber/attr_encrypted'
  
  s.has_rdoc = false
  s.rdoc_options = ['--line-numbers', '--inline-source', '--main', 'README.rdoc']
  
  s.require_paths = ['lib']
  
  s.files = %w(
    lib/attr_encrypted.rb
    lib/attr_encrypted/adapters/active_record.rb
    lib/attr_encrypted/adapters/data_mapper.rb
    lib/attr_encrypted/adapters/sequel.rb
    MIT-LICENSE
    Rakefile
    README.rdoc
    test/active_record_test.rb
    test/attr_encrypted_test.rb
    test/data_mapper_test.rb
    test/sequel_test.rb
    test/test_helper.rb
  )
  
  s.test_files = %w(
    test/active_record_test.rb
    test/attr_encrypted_test.rb
    test/data_mapper_test.rb
    test/sequel_test.rb
    test/test_helper.rb
  )
  
  s.add_dependency('eigenclass', ['>= 1.1.1'])
  s.add_dependency('encryptor', ['>= 1.1.0'])
  s.add_dependency('mocha', ['>= 0.9.8'])
end