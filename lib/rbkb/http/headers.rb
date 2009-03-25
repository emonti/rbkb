require 'uri'
require 'rbkb/helpers/named_value_array'

module Rbkb::Http

  # The Parameters class is for handling parameter named values in the 
  # form of 'q=foo&l=1&z=baz' as found in GET actions and POST 
  # www-form-urlencoded data
  class Parameters < Rbkb::NamedValueArray
    attr_accessor :opts

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

    def self.parse(str)
      return new().capture(str)
    end
  end


  # A base class for RequestHeaders and ResponseHeaders
  #
  # Includes common implementations of to_raw, to_raw_array, capture, and
  # the class method parse
  class Headers < Rbkb::NamedValueArray
    attr_accessor :opts

    def to_raw_array
      self.map {|h,v| "#{h}: #{v}" }
    end

    def to_raw
      to_raw_array.join("\r\n") << "\r\n"
    end

    def capture(str)
      raise "arg 0 must be a string" unless String === str
      heads = str.split(/\s*\r?\n/)

      # pass interim parsed headers to a block if given
      heads = yield(heads) if block_given?

      heads.each do |s| 
        h ,v = s.split(/\s*:\s*/, 2)
        self[h]=v
      end
      return self
    end

    def self.parse(str)
      return new().capture(str)
    end
  end


  # A class for HTTP Request headers.
  # Inherits from the Headers base class to add request header specific
  # behaviors and features.
  class RequestHeaders < Headers
    # This method parses a full set of raw request headers from the 'str'
    # argument. Headers are expected to include the action in the first line
    # (as in 'GET / HTTP/1.1'). The status object is returned as a 
    # RequestAction object.
    #
    # Returns a 2 element array containing [status, headers]
    def self.parse_full_headers(str)
      action = nil
      headers = new().capture(str) do |heads|
        action = RequestAction.parse(heads.shift)
        heads
      end
      return [action, headers]
    end
  end


  # A class for HTTP Response headers.
  # Inherits from the Headers base class to add response header specific
  # behaviors and features.
  class ResponseHeaders < Headers
    # This method parses a full set of raw response headers from the 'str'
    # argument. Headers are expected to include the status in the first line
    # (as in 'HTTP/1.0 200 OK'). The status object is returned as a 
    # ResponseStatus object.
    #
    # Returns a 2 element array containing [status, headers]
    def self.parse_full_headers(str)
      status = nil
      headers = new().capture(str) do |heads|
        status = ResponseStatus.parse(heads.shift)
        heads
      end
      return [status, headers]
    end
  end


  # A class for HTTP request actions, i.e. the first 
  # header sent in an HTTP request, as in "GET / HTTP/1.1"
  class RequestAction
    attr_accessor :verb, :uri, :version
    attr_reader   :opts

    def initialize(verb=nil, uri=nil, version=nil, opts=nil)
      @verb = verb || "GET"
      @uri = URI.parse(uri.to_s)
      @version = version || "HTTP/1.1"
      @opts = opts || {}
    end

    def path
      @uri.path if @uri
    end

    def parameters
      Parameters.parse(@uri.query) if @uri and @uri.query
    end

    def to_raw
      ary = [ @verb, @uri ]
      ary << @version if @version
      ary.join(" ")
    end

    # This method parses a request action String into the current instance.
    # For example:
    #
    #   include Rbkb::Http
    #   act=RequestAction
    #   act.capture("GET /foo/bar.pl?q=1&search=true HTTP/1.1")
    #   #=> #<struct Rbkb::Http::RequestAction verb="GET", \
    #   #     uri=#<URI::Generic:0x2fd582 URL:/foo/bar.pl?q=1&search=true>, \
    #   #     version="HTTP/1.1">
    #   params=act.parameters
    #   # => [["q", "1"], ["search", "true"]]
    #   params.class
    #   #=> Rbkb::Http::Parameters
    #
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


    # This method parses a request action string and returns a 
    # RequestAction object. 
    def self.parse(str)
      return new().capture(str)
    end
  end


  # A class for HTTP response status messages, i.e. the first 
  # header returned by a server, as in "HTTP/1.0 200 OK"
  class ResponseStatus
    attr_accessor :version, :code, :text
    attr_reader   :opts

    def initialize(version=nil, code=nil, text=nil, opts=nil)
      @version = version || "HTTP/1.1"
      @code = code
      @text = text
      @opts = opts || {}
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

    def self.parse(str)
      return new().capture(str)
    end
  end

end
