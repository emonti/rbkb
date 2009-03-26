require File.dirname(__FILE__) + '/test_http_helper.rb'

class TestHttp < Test::Unit::TestCase
  include Rbkb::Http
  
  def test_names
    assert_equal CommonInterface, Rbkb::Http::CommonInterface
    assert_equal Base, Rbkb::Http::Base

    assert_equal Response, Rbkb::Http::Response
    assert_equal Request, Rbkb::Http::Request
    assert_equal Parameters, Rbkb::Http::Parameters

    assert_equal Headers, Rbkb::Http::Headers
    assert_equal RequestHeaders, Rbkb::Http::RequestHeaders
    assert_equal RequestAction, Rbkb::Http::RequestAction
    assert_equal ResponseHeaders, Rbkb::Http::ResponseHeaders
    assert_equal ResponseStatus, Rbkb::Http::ResponseStatus

    assert_equal Body, Rbkb::Http::Body
    assert_equal BoundBody, Rbkb::Http::BoundBody
    assert_equal ChunkedBody, Rbkb::Http::ChunkedBody
  end

end

