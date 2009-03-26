require File.dirname(__FILE__) + '/test_http_helper.rb'

class TestHttpResponse < Test::Unit::TestCase
  include Rbkb::Http

  def setup
    @obj_klass = Response
    @obj = @obj_klass.new

    @rawdat =<<_EOF_
HTTP/1.0 404 Not Found
Date: Thu, 26 Mar 2009 01:18:52 GMT
Server: Apache
Content-Type: text/html; charset=iso-8859-1
Content-Length: 190
Connection: Keep-Alive

<html><head>
<title>Error report</title></head>
<body><h1>HTTP Status 404</h1><HR size="1" noshade><p><u>The requested resource is not available.</u></p><HR size="1" noshade>
</body></html>
_EOF_

    @hstr, @body = @rawdat.split(/^\n/, 2)
    @rawdat_crlf = @hstr.gsub("\n", "\r\n") + "\r\n" + @body

    @code = 404
    @text = "Not Found"
    @version = "HTTP/1.0"

    @headers = [
      ["Date", "Thu, 26 Mar 2009 01:18:52 GMT"],
      ["Server", "Apache"],
      ["Content-Type", "text/html; charset=iso-8859-1"], 
      ["Content-Length", "190"], 
      ["Connection", "Keep-Alive"]
    ]

    @content_length = 190
  end

  def do_type_tests(rsp)
    assert_kind_of Response, rsp
    assert_kind_of Headers, rsp.headers
    assert_kind_of Body, rsp.body
    assert_kind_of ResponseStatus, rsp.status
    assert_kind_of ResponseHeaders, rsp.headers
  end

  def do_capture_value_tests(rsp)
    assert_equal @headers, rsp.headers
    assert_equal @body, rsp.body
    assert_equal @code, rsp.status.code
    assert_equal @text, rsp.status.text
    assert_equal @version, rsp.status.version
    assert_equal @content_length, rsp.content_length
  end

  def test_init_parse
    rsp = @obj_klass.new(@rawdat)
    do_capture_value_tests(rsp)
    do_type_tests(rsp)
  end

  def test_parse
    rsp = @obj_klass.parse(@rawdat)
    do_capture_value_tests(rsp)
    do_type_tests(rsp)
  end

  def test_capture
    @obj.capture(@rawdat)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
  end

  def test_captured_body_type
    @obj.capture(@rawdat)
    assert_kind_of BoundBody, @obj.body
  end

  def test_back_to_raw
    @obj.capture(@rawdat)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
    assert_equal @rawdat_crlf, @obj.to_raw
  end

  def test_capture_crlf_headers
    @obj.capture(@rawdat_crlf)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
    assert_equal @rawdat_crlf, @obj.to_raw
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


class TestHttpResponseChunked < TestHttpResponse
  include Rbkb::Http

  def setup
    @obj_klass = Response
    @obj = @obj_klass.new

    @rawdat =<<_EOF_
HTTP/1.1 200 OK
Date: Thu, 26 Mar 2009 01:18:52 GMT
Server: Apache
Content-Type: text/html; charset=iso-8859-1
Transfer-Encoding: chunked
Connection: Keep-Alive

20
This is a test of a chunked-enco

10
ded HTTP request

0
_EOF_

    @hstr, @rawbody = @rawdat.split(/^\n/, 2)
    @rawdat_crlf = @rawdat.gsub("\n", "\r\n")
    @hdrs_crlf = @hstr.gsub("\n", "\r\n")

    @body = "This is a test of a chunked-encoded HTTP request"

    @code = 200
    @text = "OK"
    @version = "HTTP/1.1"

    @headers = [
      ["Date", "Thu, 26 Mar 2009 01:18:52 GMT"],
      ["Server", "Apache"],
      ["Content-Type", "text/html; charset=iso-8859-1"], 
      ["Transfer-Encoding", "chunked"], 
      ["Connection", "Keep-Alive"]
    ]

    @content_length = nil
    @tc_chunk_size = 0x20
  end

  def test_captured_body_type
    @obj.capture(@rawdat)
    assert_kind_of ChunkedBody, @obj.body
  end

  def test_back_to_raw
    @obj.capture(@rawdat)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
    @obj.body.opts[:output_chunk_size] = @tc_chunk_size
    assert_equal @rawdat_crlf, @obj.to_raw
  end

  def test_capture_crlf_headers
    @obj.capture(@rawdat_crlf)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
    @obj.body.opts[:output_chunk_size] = @tc_chunk_size
    assert_equal @rawdat_crlf, @obj.to_raw
  end

  def test_default_chunk_size
    if @body.size > ChunkedBody::DEFAULT_CHUNK_SIZE
      assert "TESTCASE ERROR!!!", "make the setup() @body < DEFAULT_CHUNK_SIZE"
    end
    raw_tc = "#{@hdrs_crlf}\r\n#{@body.size.to_s(16)}\r\n#{@body}\r\n\r\n0\r\n"
    @obj.capture(@rawdat_crlf)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
    assert_equal raw_tc, @obj.to_raw
  end
end

