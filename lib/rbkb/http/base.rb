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

    # Implements a common interface for an opts hash which is stored internally
    # as the class variable @opts.
    #
    # The opts hash is designed to contain various named values for 
    # configuration, etc. The values and names are determined entirely
    # by the class that uses it.
    def opts
      @opts
    end

    # Implements a common interface for setting a new opts hash containing
    # various named values for configuration, etc. This also performs a 
    # minimal sanity check to ensure the object is a Hash.
    def opts=(o=nil)
      raise "opts must be a hash" unless (o ||= {}).is_a? Hash
      @opts = o
    end
  end


  # A base class containing some common features for Request and Response 
  # objects.
  #
  # Don't use this class directly, it's intended for being overridden
  # from its derived classes or mixins.
  class Base
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    # Initializes a new Base object
    def initialize(*args)
      _common_init(*args)
    end

    # This method parses just HTTP message body. Expects body to be split
    # from the headers before-hand.
    def capture_body(bstr)
      self.body ||= default_body_obj
      @body.capture(bstr)
    end

    # This method parses only HTTP response headers. Expects headers to be 
    # split from the body before-hand.
    def capture_headers(hstr)
      self.headers ||= default_headers_obj

      if @body and not @body.capture_complete?
        return 
      elsif @headers.capture_complete?
        @status, @headers = default_headers_obj.capture_full_headers(hstr)
      else 
        @headers.capture(hstr)
      end
    end

    # This method returns the content length from Headers. This is
    # mostly useful if you are using a BoundBody object for the body.
    # 
    # Returns nil if no "Content-Length" is not found.
    #
    # The opts parameter :ignore_content_length affects this method and 
    # will cause it always to return nil.
    #
    def content_length(hdrs=@headers)
      if( (not @opts[:ignore_content_length]) and 
          hdrs and 
          hdrs["Content-Length"] =~ /^(\d+)$/ )

        $1.to_i
      end
    end

    def attach_new_header(hdr_obj=nil)
      self.headers = hdr_obj
      return hdr_obj
    end

    def attach_new_body(body_obj=nil)
      self.body = body_obj
      return body_obj
    end

    # XXX doc override!
    def default_headers_obj(*args)
      Header.new(*args)
    end

    # XXX doc override!
    def default_body_obj(*args)
      Body.new(*args)
    end

    # This method will non-destructively reset the capture state on this 
    # object and all child entities. Note, however, If child entities are not 
    # defined, it may instantiate new ones. 
    # See also: capture_complete?, reset_capture!
    def reset_capture
      if @headers
        @headers.reset_capture if not @headers.capture_complete?
      else
        attach_new_header()
      end

      if @body
        @body.reset_capture if not @body.capture_complete? 
      else
        attach_new_body()
      end
      @capture_state = nil
      self
    end

    # This method will destructively reset the capture state on this object.
    # It does so by initializing fresh child entities and discarding the old
    # ones. See also: capture_complete?, reset_capture
    def reset_capture!
      attach_new_header()
      attach_new_body()
      @capture_state = nil
      self
    end

    # Indicates whether this object is ready to capture fresh data, or is
    # waiting for additional data or a reset from a previous incomplete or 
    # otherwise broken capture. See also: reset_capture, reset_capture!
    def capture_complete?
      if( (@headers and not @headers.capture_complete?) or
          (@body and not @body.capture_complete?) )
        return false
      else
        true
      end
    end

    attr_reader :body, :headers

    # This accessor will attempt to always do the "right thing" while
    # setting this object's body entity. See: default_body_obj
    def body=(b)
      if @body
        @body.data = b
      elsif b.kind_of? Body
        @body = b.dup
        @body.opts = b.opts
      else
        @body = default_body_obj(b)
      end
      @body.base = self
      return @body
    end

    # This accessor will attempt to always do the "right thing" while
    # setting this object's headers entity. See: default_headers_obj
    def headers=(h)
      if @headers
        @headers.data = h
      elsif h.kind_of? Headers
        @headers = h.dup
        @headers.opts = h.opts
      else
        @headers = default_headers_obj(h)
      end
      @headers.base = self
      return @body
    end

  end


  # A class which encapsulates all the entities in a HTTP request
  # including the action header, general headers, and body.
  #
  # This class can also handle proxied requests using the CONNECT verb.
  class Request < Base
    attr_accessor :action, :proxy_request

    def request_parameters
      @action.parameters
    end

    # Returns a new Headers object extended as RequestHeaders. This is the 
    # default object which will be used when composing fresh Request header
    # entities.
    def default_headers_obj(*args)
      Headers.new(*args).extend(RequestHeaders)
    end

    # Returns a new BoundBody object. This is the default object which will 
    # be used when composing fresh Request body entities.
    def default_body_obj(*args)
      BoundBody.new(*args)
    end

    # Returns a raw HTTP request for this instance. The instance must have 
    # an action element defined at the bare minimum.
    #
    # FIXME: follow same conventions as Response.to_raw
    def to_raw(tmp_body=@body)
      raise "this request has no action element" unless @action
      @headers ||= Headers.request_hdr
      tmp_body ||= Body.new

      if( (not @opts[:ignore_content_length]))
        if ( len=@opts[:static_length] )
          tmp_body = BoundBody.new(tmp_body, tmp_body.opts)
          @headers["Content-Length"] = len.to_i || tmp_body.to_s.size.to_s 
        else
          @headers.delete_key("Content-Length")
        end
      end

      hdrs = (@headers).to_raw_array.unshift(@action.to_raw)
      return "#{hdrs.join("\r\n")}\r\n\r\n#{tmp_body.to_raw}"
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

      tmp_body = 
        if content_length()
          BoundBody.new() {|b| b.base = self}
        else
          Body.new() {|b| b.base = self }
        end

      tmp_body.capture(bstr)

      if act.verb.to_s.upcase == "CONNECT"
        @proxy_request = nil
        preq = self.class.new(act, hdr)
        self.capture(tmp_body)
        raise "multiple proxy CONNECT headers!" if @proxy_request
        @proxy_request = preq
      else
        @action = act
        @headers = hdr
        @body = tmp_body
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
        unless tmp_body.is_a? ChunkedBody
          tmp_body = ChunkedBody.new(tmp_body.to_s, tmp_body.opts)
          tmp_body.base = self 
        end
        tmp_hdrs.delete_key("Content-Length")
      elsif not opts[:ignore_content_length]
        unless tmp_body.is_a? BoundBody
          tmp_body = BoundBody.new(tmp_body.to_s, tmp_body.opts)
          tmp_body.base = self 
        end
        tmp_hdrs["Content-Length"] = tmp_body.to_s.size.to_s
        tmp_hdrs.delete_key("Transfer-Encoding")
      else
        tmp_body = Body.new(tmp_body.to_s) {|x| x.base = self}
      end

      hdrs = tmp_hdrs.to_raw_array.unshift(@status.to_raw)
      return "#{hdrs.join("\r\n")}\r\n\r\n#{tmp_body.to_raw}"
    end


    # Indicates whether to use chunked encoding based on presence of 
    # the "Transfer-Encoding: chunked" header and/or :ignore_chunked opts
    # parameter.
    def do_chunked_encoding?(hdrs=@headers)
      ( (not @opts[:ignore_chunked]) and 
        (hdrs["Transfer-Encoding"] =~ /(?:^|\W)chunked(?:\W|$)/) )
    end

    # Returns a new Headers object extended as ResponseHeaders. This is the 
    # default object which will be used when composing fresh Response header
    # entities.
    def default_headers_obj(*args)
      Headers.new(*args).extend(ResponseHeaders)
    end

    # Returns a new BoundBody object. This is the default object which will 
    # be used when composing fresh Response body entities.
    def default_body_obj(*args)
      BoundBody.new(*args)
    end

    # Parses a raw HTTP response and captures data into the current instance.
    def capture(str)
      raise "arg 0 must be a string" unless String === str
      hstr, bstr = str.split(/\s*\r?\n\r?\n/, 2)

      capture_headers(hstr)

      yield(self, bstr) if block_given?

      unless @body and @body.capture_complete?
        @body =
          if do_chunked_encoding?
            ChunkedBody.new {|b| b.base = self }
          elsif content_length()
            BoundBody.new {|b| b.base = self }
          else
            Body.new {|b| b.base = self }
          end
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

