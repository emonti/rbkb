require 'uri'
require 'rbkb/helpers/named_value_array'

module Rbkb::Http

  # A base class for RequestHeaders and ResponseHeaders
  #
  # Includes common implementations of to_raw, to_raw_array, capture, and
  # the class method parse
  class Headers < Rbkb::NamedValueArray
    include CommonInterface

    # Instantiates a new Headers object and returns the result of capture(str)
    def self.parse(str)
      new().capture(str)
    end

    # Instantiates a new Headers object and returns the result of 
    # capture_full_headers(str, first_klass)
    def self.parse_full_headers(str, first_klass)
      new().capture_full_headers(str, first_klass)
    end

    # Instantiates a new Headers object. 
    #
    # Parameters:
    #   raw:  String or Enumerable. Strings are parsed with capture. 
    #         Enumerables are converted with 'to_a' and stored directly.
    #
    #   opts: Options which affect the behavior of the Headers object.
    #         (none currently defined)
    #
    def initialize(raw=nil, opts=nil)
      super()
      if args.first.is_a? Enumerable
        raw=args.first
        args[0]=nil
        _common_init(*args)
        self.data = raw.to_a
      else
        _common_init(*args)
      end
    end

    attr_reader :base, :data

    def base=(b)
      if b.nil? or b.is_a? Request or b.is_a? Request # XXX
        @base = b
      else
        raise "base must be a Response or Request object or nil" 
      end
    end

    # Sets internal array data without any HTTP decoration
    def data=(d)
      self.replace d
    end

    # Returns an interim formatted array of raw "Cookie: Value" strings
    def to_raw_array
      self.map {|h,v| "#{h}: #{v}" }
    end

    # Returns a raw string of headers
    def to_raw
      to_raw_array.join("\r\n") << "\r\n"
    end

    # Captures a raw string of headers into this instance's internal array.
    # Note: This method expects not to include the first element such as a
    # RequestAction or ResponseStatus. See capture_full_headers for a version
    # that can handle this.
    def capture(str)
      raise "arg 0 must be a string" unless String === str
      heads = str.split(/\s*\r?\n/)

      # pass interim parsed headers to a block if given
      yield(heads) if block_given?

      heads.each do |s| 
        h ,v = s.split(/\s*:\s*/, 2)
        self[h]=v
      end
      return self
    end

    # See capture_full_headers. This method is used to resolve the parser
    # for 
    def get_first_klass; nil; end

    # This method parses a full set of raw headers from the 'str' argument. 
    # Unlike the regular capture method, the string is expected to start
    # with a line which will be parsed by first_klass using its parse 
    # class method. For example, first_klass would parse something like 
    # "GET / HTTP/1.1" for RequestAction or "HTTP/1.1 200 OK" for 
    # ResponseStatus. If first_klass is not defined, there will be an attempt 
    # to resolve it by calling get_first_klass
    #
    # Returns a 2 element array containing [first_entity, headers]
    # where first entity is the instantiated first_klass object and headers
    # is self.
    def capture_full_headers(str, first_klass=nil)
      if (first_klass ||= get_first_klass()).nil?
        raise "first_klass cannot be nil"
      end

      first = nil
      capture(str) do |heads|
        first = first_klass.parse(heads.shift).extend
        yield(heads) if block_given?
      end
      return [first, self]
    end

    def self.request_hdr()
      new().extend(RequestHeaders)
    end

    def self.response_hdr(*args)
      new().extend(ResponseHeaders)
    end
  end


  # A mixin for HTTP Request headers to add specific request header
  # behaviors and features.
  #
  # To instantiate a new request header, use Headers.request_hdr
  module RequestHeaders
    def get_first_klass; RequestAction; end
  end


  # A mixin for HTTP Response headers to add specific response header
  # behaviors and features.
  #
  # To instantiate a new response header, use Headers.response_hdr
  module ResponseHeaders
    def get_first_klass; ResponseStatus; end
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
      raise "arg 0 must be a string" unless String === str
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

    # Returns the URI parameter in a Parameters object if defined.
    def parameters
      Parameters.parse(query) if query
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
      raise "arg 0 must be a string" unless String === str
      unless m=/^([^\s]+)\s+(\d+)(?:\s+(.*))?$/.match(str)
        raise "invalid status #{str.inspect}"
      end
      @version = m[1]
      @code = m[2] =~ /^\d+$/ ? m[2].to_i : m[2]
      @text = m[3]
      return self
    end
  end
end

