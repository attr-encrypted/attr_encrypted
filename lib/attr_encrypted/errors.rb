module AttrEncrypted
  module Errors
    class Error < StandardError
      unless instance_methods.include?(:cause)
        attr_reader :cause

        def initialize(msg, cause=$!)
          super(msg)
          @cause = cause
        end
      end
    end

    class CipherError < Error; end
    class BadDecryptError < Error; end
    class BlockLengthError < Error; end
  end
end
