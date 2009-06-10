module Rbkb::Http

  # A base class containing some common features for Request and Response 
  # objects.
  #
  # Don't use this class directly, it's intended for being overridden
  # from its derived classes or mixins.
  class Base
    include CommonInterface

    def self.parse(*args)
      new(*args)
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

    # XXX stub
    def first_entity
      @first_entity
    end

    # XXX stub
    def first_entity=(f)
      @first_entity=(f)
    end

    # This method parses only HTTP response headers. Expects headers to be 
    # split from the body before-hand.
    def capture_headers(hstr)
      self.headers ||= default_headers_obj

      if @body and not @body.capture_complete?
        return 
      elsif @headers.capture_complete?
        self.first_entity, @headers = default_headers_obj.capture_full_headers(hstr)
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
    # will cause it always to return nil. This is useful, for example,
    # for the responses to the HTTP HEAD request method, which return
    # a Content-Length without actual content.
    #
    def content_length(hdrs=@headers)
      raise "headers is nil?" if not hdrs
      if( (not @opts[:ignore_content_length]) and 
          hdrs.get_header_value("Content-Length").to_s =~ /^(\d+)$/ )

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
    # setting this object's body entity. 
    #
    # See also: default_body_obj
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
    # setting this object's headers entity. 
    #
    # See also: default_headers_obj
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


end

