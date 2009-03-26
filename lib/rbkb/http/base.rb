require 'rbkb/helpers/named_value_array'

module Rbkb::Http
  DEFAULT_HTTP_VERSION = "HTTP/1.1"

  module CommonInterface
    # This provides a common method for use in 'initialize' to slurp in 
    # opts parameters and optionally capture a raw blob. This method also 
    # accepts a block to which it yields 'self'
    def _common_init(raw=nil, opts=nil)
      self.opts = opts
      yield self if block_given?
      capture(raw) if raw
      return self
    end

    def opts;  
      @opts
    end

    def opts=(o=nil)
      @opts = opts || {}
      raise "opts must be a hash" unless Hash === @opts
    end
  end


  # A base class containing some common features for Request and Response 
  # objects.
  #
  # Don't use this class directly, it's intended for use in inheriting 
  # from its derived classes.
  class Base
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    def initialize(*args)
      _common_init(*args)
    end

    # This method parses just HTTP message body. Expects body to be split
    # from the headers before-hand.
    def capture_body(bstr)
      self.body ||= Body.new
      @body.base = self
      @body.capture(bstr)
    end

    def content_length(hdrs=@headers)
      if hdrs and hdrs["Content-Length"] =~ /^(\d+)$/
        $1.to_i
      end
    end

    def reset_capture()
      # nop
    end

    def reset_capture!()
      # nop
    end

    def ready_to_capture?
      if @body and not @body.ready_to_capture?
        false
      else
        true
      end
    end

    attr_reader :body, :headers

    def body=(b)
      @body.data = b
    end

    def headers=(h)
      @headers.data = h
    end

  end


  # A class which encapsulates all the entities in a HTTP request
  # including the action header, general headers, and body.
  #
  # This class can also handle proxied requests using the CONNECT verb.
  class Request < Base
    attr_accessor :action, :proxy_request

    def request_path
      @action.path
    end

    def request_parameters
      @action.parameters
    end

    # Returns a raw HTTP request for this instance. The instance must have 
    # an action element defined at the bare minimum.
    def to_raw(body=@body)
      raise "this request has no action element" unless @action
      @headers ||= Headers.new {|x| x.base = self }
      if len=@opts[:static_length] or body
        @headers["Content-Length"] = len.to_i || body.to_s.size.to_s 
      end
      hdrs = (@headers).to_raw_array.unshift(@action.to_raw)
      return "#{hdrs.join("\r\n")}\r\n\r\n#{@body}"
    end

    # If a proxy_request member exists, this method will encapsulate
    # a raw HTTP request using the information in the proxy_request
    # and return a complete raw proxied request blob. If there is
    # no proxy_request defined for this object, this method will 
    # return nil.
    def to_raw_proxied(*args)
      return nil unless @proxy_request
      pbody = to_raw(*args)
      return @proxy_request.to_raw(pbody)
    end

    # Parses a raw HTTP request and captures data into the current instance.
    #
    # If a CONNECT header is encountered at the beginning, this method
    # will populate the instance's proxy_request entity. See also 
    # to_raw_proxied
    def capture(str)
      raise "arg 0 must be a string" unless String === str
      hstr, bstr = str.split(/\s*\r?\n\r?\n/, 2)
      act, hdr = Headers.request_hdr.capture_full_headers(hstr)

      bstr = nil if bstr and bstr.empty? and hdr["Content-Length"].nil?

      if act.verb.to_s.upcase == "CONNECT"
        @proxy_request = nil
        preq = self.class.new(act, hdr)
        capture(bstr)
        raise "multiple proxy CONNECT headers!" if @proxy_request
        @proxy_request = preq
      else
        @action = act
        @headers = hdr
        @body = bstr
      end
      return self
    end
  end


  # A class which encapsulates all the entities in a HTTP response,
  # including the status header, general headers, and body.
  class Response < Base
    attr_accessor :status

    # Returns a raw HTTP response for this instance. Must have a status
    # element defined at a bare minimum.
    def to_raw(tmp_body=nil)
      raise "this response has no status element" unless @status

      tmp_hdrs = @headers ? @headers.dup : Headers.new
      tmp_hdrs = yield(self, tmp_hdrs) if block_given?

      tmp_body ||= @body

      if do_chunked_encoding?(tmp_hdrs)
        tmp_hdrs.delete_key("Content-Length")
        tmp_body = ChunkedBody.new(tmp_body.to_s) {|x| x.base = self }
      else
        tmp_hdrs["Content-Length"] = tmp_body.to_s.size.to_s
        tmp_hdrs.delete_key("Transfer-Encoding")
        tmp_body = BoundBody.new(tmp_body.to_s) {|x| x.base = self }
      end

      hdrs = tmp_hdrs.to_raw_array.unshift(@status.to_raw)
      return "#{hdrs.join("\r\n")}\r\n\r\n#{tmp_body}"
    end


    # Indicates whether to use chunked encoding based on presence of 
    # the "Transfer-Encoding: chunked" header and/or :ignore_chunked opts
    # parameter.
    def do_chunked_encoding?(hdrs=@headers)
      ( (not @opts[:ignore_chunked]) and 
        (hdrs["Transfer-Encoding"] =~ /(?:^|\W)chunked(?:\W|$)/) )
    end


    # This method parses only HTTP response headers. Expects headers to be 
    # split from the body before-hand.
    def capture_headers(hstr)
      @status, @headers = Headers.response_hdr.capture_full_headers(hstr)
    end

    # Parses a raw HTTP response and captures data into the current instance.
    def capture(str)
      raise "arg 0 must be a string" unless String === str
      hstr, bstr = str.split(/\s*\r?\n\r?\n/, 2)

      capture_headers(hstr)

      # Yield self along with the 
      yield(self, bstr) if block_given?

      @body =
        if do_chunked_encoding?
          ChunkedBody.new {|b| b.base = self }
        elsif content_length()
          BoundBody.new {|b| b.base = self }
        else
          Body.new {|b| b.base = self }
        end

      capture_body(bstr)

      return self
    end
  end


  # The Parameters class is for handling named parameter values in the 
  # form of 'q=foo&l=1&z=baz' as found in GET action queries and
  # www-form-urlencoded POST body data
  class Parameters < Rbkb::NamedValueArray
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    def initialize(*args)
      _common_init(*args)
    end

    def to_raw
      self.map {|k,v| "#{k}=#{v}"}.join('&')
    end

    def capture(str)
      raise "arg 0 must be a string" unless String === str
      str.split('&').each do |p| 
        var,val = p.split('=',2)
        self[var] = val
      end
      return self
    end

  end

end

