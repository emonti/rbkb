require File.dirname(__FILE__) + '/test_http_helper.rb'

class TestHttpResponse < Test::Unit::TestCase
  include Rbkb::Http

  def setup
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

  end

  def do_type_tests(rsp)
    assert_kind_of Response, rsp
    assert_kind_of Headers, rsp.headers
    assert_kind_of Body, rsp.body
    assert_kind_of ResponseStatus, rsp.status
    assert_kind_of ResponseHeaders, rsp.headers
    assert_kind_of(@body_klass, req.body) if @body_klass
  end

  def do_capture_tests(rsp)
    assert_equal @headers, rsp.headers
    assert_equal @body, rsp.body
    assert_equal @code, rsp.status.code
    assert_equal @text, rsp.status.text
    assert_equal @version, rsp.status.version
  end

  def test_init_parse
    rsp = Response.new(@rawdat)
    do_capture_tests(rsp)
    do_type_tests(rsp)
  end

  def test_parse
    rsp = Response.parse(@rawdat)
    do_capture_tests(rsp)
    do_type_tests(rsp)
  end

  def test_capture
    rsp = Response.new().capture(@rawdat)
    do_capture_tests(rsp)
    do_type_tests(rsp)
  end

  def test_back_to_raw
    rsp = Response.parse(@rawdat)
    assert_equal @rawdat_crlf, rsp.to_raw
  end

  def test_capture_crlf_headers
    rsp = Response.parse(@rawdat_crlf)
    do_capture_tests(rsp)
    do_type_tests(rsp)
    assert_equal @rawdat_crlf, rsp.to_raw
  end
end


#class TestHttpResponseChunked < TestHttpResponse
#  include Rbkb::Http
#
#  def setup
#  end
#
#end
