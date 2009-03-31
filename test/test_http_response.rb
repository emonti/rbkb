require File.dirname(__FILE__) + '/test_http_helper.rb'

class TestHttpResponse < Test::Unit::TestCase
  include HttpTestHelper::CommonInterfaceTests

  include Rbkb::Http

  def setup
    @obj_klass = Response
    @obj_opts = nil
    @obj = @obj_klass.new(nil, @obj_opts)

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

  def test_capture_crlf_headers
    @obj.capture(@rawdat_crlf)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
    assert_equal @rawdat_crlf, @obj.to_raw
  end

  def test_captured_body_type
    @obj.capture(@rawdat)
    assert_kind_of BoundBody, @obj.body
  end
end


class TestHttpResponseChunked < TestHttpResponse
  include Rbkb::Http

  def setup
    @obj_klass = Response
    @obj_opts = {}
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

# This test-case simulates a HTTP response to a HEAD request. This type of
# response is special since it returns Content-Length: NNN or 
# Transfer-Encoding: chunked headers without any actual body data. 
# To handle this special situation, we use the 'ignore_content_length' and 
# 'ignore_chunked_encoding' options.
class TestHttpResponseToHead < TestHttpResponse
  def setup
    @obj_klass = Response

    # Technically, a server should only respond to HEAD with one of 
    # content length *or* chunked encoding. However, we ignore them both.
    @obj_opts = {
      :ignore_content_length => true, 
      :ignore_chunked_encoding => true
    }
    @obj = @obj_klass.new(nil, @obj_opts)

    # Note, our test-case includes both content length and chunked encoding.
    # A real server probably wouldn't do this, but we want to make sure
    # we handle both.
    @rawdat =<<_EOF_
HTTP/1.1 200 OK
Cache-Control: private, max-age=0
Date: Fri, 27 Mar 2009 04:27:27 GMT
Expires: -1
Content-Length: 9140
Content-Type: text/html; charset=ISO-8859-1
Server: Booble
Transfer-Encoding: chunked

_EOF_

    @hstr, @body = @rawdat.split(/^\n/, 2)
    @rawdat_crlf = @hstr.gsub("\n", "\r\n") + "\r\n" + @body

    @code = 200
    @text = "OK"
    @version = "HTTP/1.1"

    @headers = [
      ["Cache-Control", "private, max-age=0"], 
      ["Date", "Fri, 27 Mar 2009 04:27:27 GMT"], 
      ["Expires", "-1"], 
      ["Content-Length", "9140"], 
      ["Content-Type", "text/html; charset=ISO-8859-1"], 
      ["Server", "Booble"], 
      ["Transfer-Encoding", "chunked"]
    ]

    # Content length should get ignored
    @content_length = nil
  end

  def test_capture_crlf_headers
    @obj.capture(@rawdat_crlf)
    do_capture_value_tests(@obj)
    do_type_tests(@obj)
    assert_equal @rawdat_crlf, @obj.to_raw
  end

  def test_captured_body_type
    @obj.capture(@rawdat)
    assert_kind_of Body, @obj.body
  end

end

