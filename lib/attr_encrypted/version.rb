module AttrEncrypted
  # Contains information about this gem's version
  module Version
    MAJOR = 1
    MINOR = 3
    PATCH = 5

    # Returns a version string by joining <tt>MAJOR</tt>, <tt>MINOR</tt>, and <tt>PATCH</tt> with <tt>'.'</tt>
    #
    # Example
    #
    #   Version.string # '1.0.2'
    def self.string
      [MAJOR, MINOR, PATCH].join('.')
    end
  end
end
