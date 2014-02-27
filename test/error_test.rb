require File.expand_path('../test_helper', __FILE__)

class ErrorTest < Test::Unit::TestCase
  def test_cause_capture
    begin
      begin
        raise 'heck'
      rescue
        raise AttrEncrypted::Errors::Error, 'This is my error, there are many like it...'
      end
    rescue AttrEncrypted::Errors::Error => ex
      assert_not_nil ex.cause
    end
  end
end
