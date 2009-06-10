require 'uri'

module Rbkb::Http

  # A base class for RequestHeaders and ResponseHeaders
  #
  # Includes common implementations of to_raw, to_raw_array, capture, and
  # the class method parse
  #
  # The Headers array are stored internally as an named value pairs array.
  #
  # The headers are generally name/value pairs in the form of:
  #
  #   [  ["Name1", "value1"], ["Name2", "value2"], ...  ]
  #
  # Which will be rendered with to_raw() to (or captured with capture() from):
  #
  #   Name1: value1
  #   Name2: value2
  #   ...
  #
  # This has the benefit of letting the data= accessor automatically render a 
  # Hash or any other Enumerable to a Headers object through the use of to_a.
  # However it has the caveat that named pairs are expected on various 
  # operations.
  class Headers < Array
    include CommonInterface

    # Class method to instantiate a new RequestHeaders object
    def self.request_hdr(*args)
      Headers.new(*args).extend(RequestHeaders)
    end

    # Class method to instantiate a new ResponseHeaders object
    def self.response_hdr(*args)
      Headers.new(*args).extend(ResponseHeaders)
    end

    # Instantiates a new Headers object and returns the result of capture(str)
    # Note, this method does not distinguish between ResponseHeaders or
    # RequestHeaders, and so the object may need to be extended with one
    # or the other, if you need access to specific behviors from either.
    def self.parse(str)
      new().capture(str)
    end

    # Instantiates a new Headers object and returns the result of 
    # capture_full_headers(str, first_obj)
    def self.parse_full_headers(str, first_obj)
      new().capture_full_headers(str, first_obj)
    end

    # Instantiates a new Headers object. 
    #
    # Arguments:
    #   raw:  String or Enumerable. Strings are parsed with capture. 
    #         Enumerables are converted with 'to_a' and stored directly.
    #
    #   opts: Options which affect the behavior of the Headers object.
    #         (none currently defined)
    #
    def initialize(*args)
      super()
      if args.first.kind_of? Enumerable
        raw=args.first
        args[0]=nil
        _common_init(*args)
        self.data = raw.to_a
      else
        _common_init(*args)
      end
    end

    attr_reader :base

    # Conditionally sets the @base class variable if it is a kind of Base
    # object.
    def base=(b)
      if b.nil? or b.kind_of? Base
        @base = b
      else
        raise "base must be a kind of Base object or nil" 
      end
    end

    # The data method provides a common interface to access internal
    # non-raw information stored in the object.
    #
    # The Headers incarnation returns the internal headers array 
    # (actually self).
    def data
      self
    end

    # The data= method provides a common interface to access internal
    # non-raw information stored in the object.
    #
    # This method stores creates a shallow copy for anything but another 
    # Headers object which it references directly. A few rules are enforced:
    #   * 1-dimensional elements will be expanded to tuples with 'nil' as the 
    #     second value. 
    #
    #   * Names which are enumerables will be 'join()'ed, but not values.
    def data=(d)
      if d.kind_of? Headers
        self.replace d
      else
        self.replace []
        d.to_a.each do |k, v| 
          k = k.to_s if k.is_a? Numeric
          self << [k,v]
        end
      end
      return self
    end

    # The to_raw_array method returns an interim formatted array of raw 
    # "Cookie: Value" strings.
    def to_raw_array
      self.map {|h,v| "#{h}: #{v}" }
    end

    def get_all(k)
      self.select {|h| h[0].downcase == k.downcase }
    end

    def get_all_values_for(k)
      self.get_all(k).collect {|h,v| v }
    end
    alias all_values_for get_all_values_for

    def get_header(k)
      self.find {|h| h[0].downcase == k.downcase }
    end

    def get_value_for(k)
      if v= self.get_header(k)
        return h[1]
      end
    end
    alias get_header_value get_value_for
    alias value_for get_value_for
    
    def delete_header(k)
      self.delete_if {|h| h[0].downcase == k.downcase }
    end
    
    def set_header(k,v)
      sel = get_header(k)

      if sel.empty?
        self << [k,v]
        return [[k,v]]
      else
        sel.each {|h| h[1] = v }
        return sel
      end
    end
    alias set_all_for set_header

    # The to_raw method returns a raw string of headers as they appear
    # on the wire.
    def to_raw
      to_raw_array.join("\r\n") << "\r\n"
    end

    # Captures a raw string of headers into this instance's internal array.
    # Note: This method expects not to include the first element such as a
    # RequestAction or ResponseStatus. See capture_full_headers for a version
    # that can handle this.
    def capture(str)

      raise "arg 0 must be a string" unless str.is_a?(String)
      heads = str.split(/\s*\r?\n/)

      # pass interim parsed headers to a block if given
      yield(self, heads) if block_given?

      self.replace [] if capture_complete? 
      heads.each do |s| 
        k,v = s.split(/\s*:\s*/, 2) 
        self << [k,v]
      end
      return self
    end

    # See capture_full_headers. This method is used to resolve the parser
    # for the first entity above the HTTP headers. This instance is designed
    # to raise an exception when capturing.
    def get_first_obj; raise "get_first_obj called on base stub"; end

    # This method parses a full set of raw headers from the 'str' argument. 
    # Unlike the regular capture method, the string is expected to start
    # with a line which will be parsed by first_obj using its own capture 
    # method. For example, first_obj would parse something like 
    # "GET / HTTP/1.1" for RequestAction or "HTTP/1.1 200 OK" for 
    # ResponseStatus. If first_obj is not defined, there will be an attempt 
    # to resolve it by calling get_first_obj which should return the 
    # appropriate type of object or raise an exception.
    #
    # Returns a 2 element array containing [first_entity, headers]
    # where first entity is the instantiated first_obj object and headers
    # is self.
    def capture_full_headers(str, first_obj=nil)
      first_obj ||= get_first_obj() {|x|}

      first = nil
      capture(str) do |this, heads|
        first = first_obj.capture(heads.shift)
        yield(heads) if block_given?
      end
      return [first, self]
    end

    # This method will non-destructively reset the capture state on this object.
    # The existing headers are maintained when this is called.
    # See also: capture_complete? reset_capture!
    def reset_capture
      @capture_state = nil
      self
    end

    # This method will destructively reset the capture state on this object.
    # The existing headers array is emptied when this is called.
    # See also: capture_complete?, reset_capture
    def reset_capture!
      @capture_state = nil
      self.data = []
    end

    # Indicates whether this object is ready to capture fresh data, or is
    # waiting for additional data or a reset from a previous incomplete or 
    # otherwise broken capture. See also: reset_capture, reset_capture!
    def capture_complete?
      not @capture_state
    end
  end


  # A mixin for HTTP Request headers to add specific request header
  # behaviors and features.
  #
  # To instantiate a new request header, use Headers.request_hdr
  module RequestHeaders
    # This method is used to resolve the parser for the first entity above the 
    # HTTP headers. The incarnation for ResponseHeaders returns ResponseStatus
    # See Headers.capture_full_headers for more information.
    def get_first_obj(*args)
      RequestAction.new(*args)
    end
  end


  # A mixin for HTTP Response headers to add specific response header
  # behaviors and features.
  #
  # To instantiate a new response header, use Headers.response_hdr
  module ResponseHeaders

    # This method is used to resolve the parser for the first entity above the 
    # HTTP headers. The incarnation for ResponseHeaders returns ResponseStatus
    # See Headers.capture_full_headers for more information.
    def get_first_obj(*args)
      ResponseStatus.new(*args)
    end
  end


  # A class for HTTP request actions, i.e. the first 
  # header sent in an HTTP request, as in "GET / HTTP/1.1"
  class RequestAction
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    attr_accessor :verb, :uri, :version

    def initialize(*args)
      _common_init(*args)
      @verb ||= "GET"
      @uri ||= URI.parse("/")
      @version ||= "HTTP/1.1"
    end

    def to_raw
      ary = [ @verb, @uri ]
      ary << @version if @version
      ary.join(" ")
    end

    # This method parses a request action String into the current instance.
    def capture(str)
      raise "arg 0 must be a string" unless str.is_a?(String)
      unless m=/^([^\s]+)\s+([^\s]+)(?:\s+([^\s]+))?\s*$/.match(str)
        raise "invalid action #{str.inspect}"
      end
      @verb = m[1]
      @uri = URI.parse m[2]
      @version = m[3]
      return self
    end

    # Returns the URI path as a String if defined
    def path
      @uri.path if @uri
    end

    # Returns the URI query as a String if it is defined
    def query
      @uri.query if @uri
    end

    # Returns the URI query parameters as a FormUrlencodedParams object if 
    # the query string is defined.
    # XXX note parameters cannot currently be modified in this form.
    def parameters
      FormUrlencodedParams.parse(query) if query
    end

    attr_reader :base

    def base=(b)
      raise "base must be a kind of Base object" if not b.is_a? Base
      @base = b
    end
  end


  # A class for HTTP response status messages, i.e. the first 
  # header returned by a server, as in "HTTP/1.0 200 OK"
  class ResponseStatus
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    attr_accessor :version, :code, :text

    def initialize(*args)
      _common_init(*args)
      @version ||= DEFAULT_HTTP_VERSION
    end

    def to_raw
      [@version, @code, @text].join(" ")
    end

    def capture(str)
      raise "arg 0 must be a string" unless str.is_a?(String)
      unless m=/^([^\s]+)\s+(\d+)(?:\s+(.*))?$/.match(str)
        raise "invalid status #{str.inspect}"
      end
      @version = m[1]
      @code = m[2] =~ /^\d+$/ ? m[2].to_i : m[2]
      @text = m[3]
      return self
    end

    attr_reader :base

    def base=(b)
      raise "base must be a kind of Base object" if not b.is_a? Base
      @base = b
    end
  end
end

