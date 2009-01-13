attr\_encrypted
===============

Generates attr\_accessors that encrypt and decrypt attributes transparently

It works with ANY class, however, you get a few extra features when you're using it with ActiveRecord, DataMapper, or Sequel


Installation
------------

	gem install shuber-attr_encrypted --source http://gems.github.com


Usage
-----

### Basic ###

Encrypting attributes has never been easier:

	class User
	  attr_accessor :name
	  attr_encrypted :ssn, :key => 'a secret key'
	
	  def load
	    # loads the stored data
	  end
	
	  def save
	    # saves the :name and :encrypted_ssn attributes somewhere (e.g. filesystem, database, etc)
	  end
	end
	
	@user = User.new
	@user.ssn = '123-45-6789'
	@user.encrypted_ssn # returns the encrypted version of :ssn
	@user.save
	
	@user = User.load
	@user.ssn # decrypts :encrypted_ssn and returns '123-45-6789'


### Specifying the encrypted attribute name ###

By default, the encrypted attribute name is `encrypted_#{attribute}` (e.g. `attr_encrypted :email` would create an attribute named `encrypted_email`).
You have a couple of options if you want to name your attribute something else.

#### The `:attribute` option ####

You can simply pass the name of the encrypted attribute as the `:attribute` option:

	class User
	  attr_encrypted :email, :key => 'a secret key', :attribute => 'email_encrypted'
	end

This would generate an attribute named `email_encrypted`


#### The `:prefix` and `:suffix` options ####

If you're planning on encrypting a few different attributes and you don't like the `encrypted_#{attribute}` naming convention then you can specify your own:

	class User
	  attr_encrypted :email, :credit_card, :ssn, :key => 'a secret key', :prefix => 'secret_', :suffix => '_crypted'
	end

This would generate the following attributes: `secret_email_crypted`, `secret_credit_card_crypted`, and `secret_ssn_crypted`.


### Encryption keys ###

Although a `:key` option may not be required (see custom encryptor below), it has a few special features

#### Unique keys for each attribute ####

You can specify unique keys for each attribute if you'd like:

	class User
	  attr_encrypted :email, :key => 'a secret key'
	  attr_encrypted :ssn, :key => 'a different secret key'
	end


#### Symbols representing instance methods as keys ####

If your class has an instance method that determines the encryption key to use, simply pass a symbol representing it like so:

	class User
	  attr_encrypted :email, :key => :encryption_key
	
	  def encryption_key
	    # does some fancy logic and returns an encryption key
	  end
	end


#### Procs as keys ####

You can pass a proc/lambda object as the `:key` option as well:

	class User
	  attr_encrypted :email, :key => proc { |user| ... }
	end


### Conditional encrypting ###

There may be times that you want to only encrypt when certain conditions are met. For example maybe you're using rails and you don't want to encrypt 
attributes when you're in development mode. You can specify conditions like this:

	class User < ActiveRecord::Base
	  attr_encrypted :email, :key => 'a secret key', :unless => Rails.env.development?
	end

You can specify both `:if` and `:unless` options. If you pass a symbol representing an instance method then the result of the method will be evaluated. 
Any objects that respond to `:call` are evaluated as well.


### Custom encryptor ###

The [Huberry::Encryptor](http://github.com/shuber/encryptor) class is used by default. You may use your own custom encryptor by specifying
the `:encryptor`, `:encrypt_method`, and `:decrypt_method` options

Lets suppose you'd like to use this custom encryptor class:

	class SillyEncryptor
	  def self.silly_encrypt(options)
	    (options[:value] + options[:secret_key]).reverse
	  end
	
	  def self.silly_decrypt(options)
	    options[:value].reverse.gsub(/#{options[:secret_key]}$/, '')
	  end
	end

Simply set up your class like so:

	class User
	  attr_encrypted :email, :secret_key => 'a secret key', :encryptor => SillyEncryptor, :encrypt_method => :silly_encrypt, :decrypt_method => :silly_decrypt
	end

Any options that you pass to `attr_encrypted` will be passed to the encryptor along with the `:value` option which contains the string to encrypt/decrypt.
Notice it uses `:secret_key` instead of `:key`.


### Custom algorithms ###

The default [Huberry::Encryptor](http://github.com/shuber/encryptor) uses the standard ruby OpenSSL library. It's default algorithm is `aes-256-cbc`. You can
modify this by passing the `:algorithm` option to the `attr_encrypted` call like so:

	class User
	  attr_encrypted :email, :key => 'a secret key', :algorithm => 'bf'
	end

Run `openssl list-cipher-commands` to view a list of algorithms supported on your platform. See [http://github.com/shuber/encryptor](http://github.com/shuber/encryptor) for more information.

	aes-128-cbc
	aes-128-ecb
	aes-192-cbc
	aes-192-ecb
	aes-256-cbc
	aes-256-ecb
	base64
	bf
	bf-cbc
	bf-cfb
	bf-ecb
	bf-ofb
	cast
	cast-cbc
	cast5-cbc
	cast5-cfb
	cast5-ecb
	cast5-ofb
	des
	des-cbc
	des-cfb
	des-ecb
	des-ede
	des-ede-cbc
	des-ede-cfb
	des-ede-ofb
	des-ede3
	des-ede3-cbc
	des-ede3-cfb
	des-ede3-ofb
	des-ofb
	des3
	desx
	idea
	idea-cbc
	idea-cfb
	idea-ecb
	idea-ofb
	rc2
	rc2-40-cbc
	rc2-64-cbc
	rc2-cbc
	rc2-cfb
	rc2-ecb
	rc2-ofb
	rc4
	rc4-40


### Default options ###

Let's imagine that you have a few attributes that you want to encrypt with different keys, but you don't like the `encrypted_#{attribute}` naming convention.
Instead of having to define your class like this:

	class User
	  attr_encrypted :email, :key => 'a secret key', :prefix => '', :suffix => '_crypted'
	  attr_encrypted :ssn, :key => 'a different secret key', :prefix => '', :suffix => '_crypted'
	  attr_encrypted :credit_card, :key => 'another secret key', :prefix => '', :suffix => '_crypted'
	end

You can simply define some default options like so:

	class User
	  attr_encrypted_options.merge!(:prefix => '', :suffix => '_crypted')
	  attr_encrypted :email, :key => 'a secret key'
	  attr_encrypted :ssn, :key => 'a different secret key'
	  attr_encrypted :credit_card, :key => 'another secret key'
	end

This should help keep your classes clean and DRY.


### Encoding ###

You're probably going to be storing your encrypted attributes somehow (e.g. filesystem, database, etc) and may run into some issues trying to store a weird
encrypted string. I've had this problem myself using MySQL. You can simply pass the `:encode` option to automatically encode/decode when encrypting/decrypting.

	class User
	  attr_encrypted :email, :key => 'some secret key', :encode => true
	end

The default encoding is `m*` (base64). You can change this by setting `:encode => 'some encoding'`. See  [Array#pack](http://www.ruby-doc.org/core/classes/Array.html#M002245) for more encoding options.


### Marshaling ###

You may want to encrypt objects other than strings (e.g. hashes, arrays, etc). If this is the case, simply pass the `:marshal` option to automatically marshal
when encrypting/decrypting.

	class User
	  attr_encrypted :credentials, :key => 'some secret key', :marshal => true
	end


### Encrypt/decrypt attribute methods ###

If you use the same key to encrypt every record (per attribute) like this:

	class User
	  attr_encrypted :email, :key => 'a secret key'
	end

Then you'll have these two class methods available for each attribute: `User.encrypt_email(email_to_encrypt)` and `User.decrypt_email(email_to_decrypt)`. This can
be useful when you're using ActiveRecord (see below).


### ActiveRecord ###

If you're using this gem with ActiveRecord, you get a few extra features:

#### Default options ####

For your convenience, the `:encode` option is set to true by default since you'll be storing everything in a database.


#### Dynamic find\_by\_ and scoped\_by\_ methods ####

Let's say you'd like to encrypt your user's email addresses, but you also need a way for them to login. Simply set up your class like so:

	class User < ActiveRecord::Base
	  attr_encrypted :email, :key => 'a secret key'
	  attr_encrypted :password, :key => 'some other secret key'
	end

You can now lookup and login users like so:

	User.find_by_email_and_password('test@example.com', 'testing')

The call to `find_by_email_and_password` is intercepted and modified to `find_by_encrypted_email_and_encrypted_password('ENCRYPTED EMAIL', 'ENCRYPTED PASSWORD')`.
The dynamic scope methods like `scoped_by_email_and_password` work the same way.

NOTE: This only works if all records are encrypted with the same encryption key (per attribute).


### DataMapper and Sequel ###

Just like the default options for ActiveRecord, the `:encode` option is set to true by default since you'll be storing everything in a database.


Contact
-------

Problems, comments, and suggestions all welcome: [shuber@huberry.com](mailto:shuber@huberry.com)