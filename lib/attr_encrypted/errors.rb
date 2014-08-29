module AttrEncrypted
  class Error < StandardError
    unless instance_methods.include?(:cause)
      attr_reader :cause

      def initialize(msg = '', cause = $!)
        super(msg)
        @cause = cause
      end
    end
  end

  module Errors
    class CipherError < Error; end
    class BadDecryptError < Error; end
    class BlockLengthError < Error; end
    class IVLengthError < Error; end
  end
end
