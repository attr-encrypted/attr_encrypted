attr\_encrypted
===============

Generates attr\_accessors that encrypt and decrypt attributes transparently


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

You can pass a proc object as the `:key` option as well:

	class User
	  attr_encrypted :email, :key => proc { |user| ... }
	end


### Custom encryptor ###

You may use your own custom encryptor by specifying the `:encryptor`, `:encrypt_method`, and `:decrypt_method` options

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
	  attr_encrypted_options.merge(:prefix => '', :suffix => '_crypted')
	  attr_encrypted :email, :key => 'a secret key'
	  attr_encrypted :ssn, :key => 'a different secret key'
	  attr_encrypted :credit_card, :key => 'another secret key'
	end

This should help keep your classes clean and DRY.


Contact
-------

Problems, comments, and suggestions all welcome: [shuber@huberry.com](mailto:shuber@huberry.com)