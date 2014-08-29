require File.expand_path('../test_helper', __FILE__)

class ErrorTest < Test::Unit::TestCase
  def test_cause_capture
    begin
      begin
        raise 'heck'
      rescue
        raise AttrEncrypted::Error
       end
     rescue AttrEncrypted::Error => ex
       assert_not_nil ex.cause
     end
   end
 end
