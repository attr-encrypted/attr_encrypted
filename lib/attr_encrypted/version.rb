# frozen_string_literal: true

module AttrEncrypted
  # Contains information about this gem's version
  module Version
    MAJOR = 3
    MINOR = 2
    PATCH = 0

    # Returns a version string by joining <tt>MAJOR</tt>, <tt>MINOR</tt>, and <tt>PATCH</tt> with <tt>'.'</tt>
    #
    # Example
    #
    #   Version.string # '1.0.2'
    def self.string
      [MAJOR, MINOR, PATCH].join('.')
    end

    # Return current version as a `Gem::Version` object (for easier comparison)
    #
    # @return [Gem::Version] the current version of the gem
    def get
      ::Gem::Version.new string
    end
  end
end
