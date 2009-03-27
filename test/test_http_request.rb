require File.dirname(__FILE__) + '/test_http_helper.rb'

class TestHttpRequest < Test::Unit::TestCase
  include HttpTestHelper::CommonInterfaceTests

  include Rbkb::Http

  def setup
    @obj_klass = Request
    @obj = @obj_klass.new

    @rawdat =<<_EOF_
GET /csi?v=3&s=webhp&action=&tran=undefined HTTP/1.1
Host: www.google.com
User-Agent: Mozilla/5.0
Accept: image/png,image/*;q=0.8,*/*;q=0.5
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Keep-Alive: 300
Proxy-Connection: keep-alive
Referer: http://www.google.com/
Cookie: PREFID=XXXX:LM=1237996892:S=YYYYY; NID=111

_EOF_

    @hstr, @body = @rawdat.split(/^\n/, 2)
    @rawdat_crlf = @hstr.gsub("\n", "\r\n") + "\r\n" + @body

    @verb = "GET"
    @uri = "/csi?v=3&s=webhp&action=&tran=undefined"
    @path, @query = @uri.split('?',2)
    @req_parameters = [
      ["v", "3"], 
      ["s", "webhp"], 
      ["action", ""], 
      ["tran", "undefined"]
    ]
    @version = "HTTP/1.1"

    @headers = [
      ["Host", "www.google.com"], 
      ["User-Agent", "Mozilla/5.0"],
      ["Accept", "image/png,image/*;q=0.8,*/*;q=0.5"], 
      ["Accept-Language", "en-us,en;q=0.5"], 
      ["Accept-Encoding", "gzip,deflate"], 
      ["Accept-Charset", "ISO-8859-1,utf-8;q=0.7,*;q=0.7"], 
      ["Keep-Alive", "300"], 
      ["Proxy-Connection", "keep-alive"], 
      ["Referer", "http://www.google.com/"], 
      ["Cookie", "PREFID=XXXX:LM=1237996892:S=YYYYY; NID=111"],
    ]
  end

  def do_type_tests(req)
    assert_kind_of Request, req
    assert_kind_of Headers, req.headers
    assert_kind_of Body, req.body
    assert_kind_of RequestAction, req.action
    assert_kind_of RequestHeaders, req.headers
  end

  def do_capture_value_tests(req)
    assert_equal @headers, req.headers
    assert_equal @body, req.body.to_s
    assert_equal @uri, req.action.uri.to_s
    assert_equal @path, req.action.uri.path
    assert_equal @query, req.action.uri.query
    assert_equal @verb, req.action.verb
    assert_equal @version, req.action.version
    assert_equal @req_parameters, req.request_parameters
  end

  def test_capture_crlf_headers
    req = @obj.capture(@rawdat_crlf)
    do_capture_value_tests(req)
    do_type_tests(req)
    assert_equal @rawdat_crlf, req.to_raw
  end

  def test_captured_body_type
    @obj.capture(@rawdat)
    assert_kind_of Body, @obj.body
  end

end


class TestHttpPostRequest < TestHttpRequest

  def setup
    @obj_klass = Request
    @obj = @obj_klass.new

    @rawdat =<<_EOF_
POST /path/script.cgi?qtype=foo HTTP/1.0
From: frog@jmarshall.com
HasColon: this_has_a_colon:yikes
User-Agent: HTTPTool/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 32

home=Cosby&favorite+flavor=flies
_EOF_
    @rawdat.chomp!

    @hstr, @body = @rawdat.split(/^\n/, 2)
    @rawdat_crlf = @hstr.gsub("\n", "\r\n") + "\r\n" + @body

    @verb = "POST"
    @uri = "/path/script.cgi?qtype=foo"
    @path, @query = @uri.split('?',2)
    @req_parameters = [
      ["qtype", "foo"], 
    ]
    @version = "HTTP/1.0"

    @headers = [
      ["From", "frog@jmarshall.com"],
      ["HasColon", "this_has_a_colon:yikes"],
      ["User-Agent", "HTTPTool/1.0"],
      ["Content-Type", "application/x-www-form-urlencoded"],
      ["Content-Length", "32"],
    ]

     @post_parameters = [["home", "Cosby"], ["favorite+flavor", "flies"]]
  end

  def test_captured_body_type
    @obj.capture(@rawdat)
    assert_kind_of BoundBody, @obj.body
  end


end

