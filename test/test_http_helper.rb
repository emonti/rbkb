require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'rbkb/http'

module HttpTestHelper
  # contains various test cases to test common interface features
  module CommonInterfaceTests

    def setup()
      raise "Helper stub called. Override setup() in TestCase"
    end

    def do_type_tests(x)
      raise "Helper stub called. Override do_type_tests() in TestCase"
    end

    def do_type_tests(x)
      raise "Helper stub called. Override do_capture_value_tests() in TestCase"
    end

    def test_init_parse
      req = @obj_klass.new(@rawdat)
      do_capture_value_tests(req)
      do_type_tests(req)
    end

    def test_parse
      req = @obj_klass.parse(@rawdat)
      do_capture_value_tests(req)
      do_type_tests(req)
    end

    def test_capture
      req = @obj.capture(@rawdat)
      do_capture_value_tests(req)
      do_type_tests(req)
    end

    def test_back_to_raw
      req = @obj.capture(@rawdat)
      assert_equal @rawdat_crlf, req.to_raw
    end

    def test_capture_and_reuse_nondestructive
      @obj.capture(@rawdat_crlf)
      @obj.reset_capture
      @obj.capture(@rawdat_crlf)
      do_capture_value_tests(@obj)
      do_type_tests(@obj)
    end

    def test_capture_and_reuse_destructive
      @obj.capture(@rawdat_crlf)
      @obj.reset_capture!
      @obj.capture(@rawdat_crlf)
      do_capture_value_tests(@obj)
      do_type_tests(@obj)
    end

  end
end
