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


Contact
-------

Problems, comments, and suggestions all welcome: [shuber@huberry.com](mailto:shuber@huberry.com)