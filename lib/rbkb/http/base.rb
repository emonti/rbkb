require 'stringio'

module Rbkb::Http

  # A class which encapsulates all the entities in a HTTP request
  # including the action header, general headers, and body.
  #
  # This class can also handle proxied requests using the CONNECT verb.
  class Request
    attr_accessor :action, :headers, :body, :proxy_request
    attr_reader   :opts

    def initialize(action=nil, headers=nil, body=nil, opts=nil)
      @action = action || RequestAction.new
      @headers = action || RequestHeaders.new
      @body = body
      @opts = opts || {}
    end

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
      @headers["Content-Length"] = body.to_s.size.to_s if body
      hdrs = (@headers).to_raw_array.unshift(@action.to_raw)
      return "#{hdrs.join("\r\n")}\r\n\r\n#{@body}"
    end

    # If a proxy_request member exists, this method will encapsulate
    # a raw HTTP request using the information in the proxy_request
    # and return a complete raw proxied request blob. If there is
    # no proxy_request defined for this object, this method will 
    # return nil.
    def to_raw_proxied
      return nil unless @proxy_request
      pbody = to_raw()
      return @proxy_request.to_raw(pbody)
    end

    # Parses a raw HTTP response into the current instance.
    #
    # If a CONNECT HEADER is encountered at the beginning, this method
    # will populate the instance's proxy_request entity. See 'to_raw_proxied'
    #
    def capture(str)
      raise "arg 0 must be a string" unless String === str
      hstr, bstr = str.split(/\s*\r?\n\r?\n/, 2)
      act, hdr = RequestHeaders.parse_full_headers(hstr)

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

    def self.parse(str)
      return new().capture(str)
    end
  end


  # A class which encapsulates all the entities in a HTTP response
  # including the status header, general headers, and body.
  class Response
    attr_accessor :status, :headers, :body
    attr_reader :opts, :chunked_in_progress

    def initialize(status=nil, headers=nil, body=nil, opts=nil)
      @status = status || ResponseStatus.new
      @headers = headers || ResponseHeaders.new
      @body = body
      @opts = opts ||= {}
    end

    # Returns a raw HTTP response for this instance. Must have a status
    # element defined at a bare minimum.
    def to_raw(body=@body)
      raise "this response has no status element" unless @status

      if( (not @opts[:no_chunked]) and 
          @headers["Transfer-Encoding"] =~ /(?:^|\W)chunked(?:\W|$)/ )
        bstr = "#{self.body.size.to_hex}\r\n#{self.body}\r\n\r\n0\r\n"
      else
        @headers["Content-Length"] = @body.to_s.size.to_s
        bstr = @body
      end

      hdrs = @headers.to_raw_array.unshift(@status.to_raw)
      return "#{hdrs.join("\r\n")}\r\n\r\n#{bstr}"
    end



    # Handles "Transfer-Encoding: chunked" for body captures
    # Throws :more_chunks when given incomplete data and expects to be
    # called again with more body data to parse. Caller can check for this
    # condition by checking the chunked_in_progress attribute.
    def capture_chunked(str)
      # chunked encoding is so gross...
      if @chunked_in_progress
        sio = StringIO.new(@last_chunk.to_s + str)
        @last_chunk = nil
      else
        @body = ""
        sio = StringIO.new(str)
      end

      @chunked_in_progress = true
      while not sio.eof?
        unless m=/^([a-fA-F0-9]+)\s*(;[[:print:]\s]*)?\r?\n$/.match(line=sio.readline)
          raise "invalid chunk at #{line.chomp.inspect}"
        end
        if (chunksz = m[1].hex) == 0
          @chunked_in_progress = false
          # XXX ignore Trailer fields
          break
        end

        if ( (not sio.eof?) and 
             (chunk=sio.read(chunksz)) and 
             chunk.size == chunksz and 
             (not sio.eof?) and (extra = sio.readline) and
             (not sio.eof?) and (extra << sio.readline)
           )
          if extra =~ /^\r?\n\r?\n$/
            @body << chunk
          else
            raise "expected CRLF"
          end
        else
          @last_chunk = line + chunk.to_s + extra.to_s
          break
        end
      end
      throw(:more_chunks, self) if @chunked_in_progress
      return self
    end

    # Parses a raw HTTP response into the current instance.
    def capture(str)
      raise "arg 0 must be a string" unless String === str
      hstr, bstr = str.split(/\s*\r?\n\r?\n/, 2)
      @status, @headers = ResponseHeaders.parse_full_headers(hstr)
      if ( (not @opts[:no_chunked]) and 
           @headers["Transfer-Encoding"] =~ /(?:^|\W)chunked(?:\W|$)/ )
        @chunked_in_progress = @last_chunk = nil
        capture_chunked(bstr)
      else
        @body = bstr
      end
      return self
    end

    # Parses a raw HTTP response and returns a new Response object.
    def self.parse(str)
      return new().capture(str)
    end
  end
end

