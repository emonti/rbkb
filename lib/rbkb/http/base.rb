module Rbkb::Http

  # A class which encapsulates all the entities in a HTTP request
  # including the action header, general headers, and body.
  #
  # This class can also handle proxied requests using CONNECT headers.
  #
  # TODO: handle chunked encoding in to_raw and capture
  class Request < Struct.new(:action, :headers, :body, :proxy_request)
    def request_path
      action.path
    end

    def request_parameters
      action.parameters
    end

    # Returns a raw HTTP request for this instance. The instance must have 
    # an action element defined at the bare minimum.
    def to_raw(body=self.body)
      req=self
      raise "this request has no action element" unless a=req.action

      action = a.to_raw
      req.headers["Content-Length"] = body.to_s.size.to_s if body
      headers = (req.headers).to_raw_array.unshift(action)

      return "#{headers.join("\r\n")}\r\n\r\n#{req[:body]}"
    end

    # If a proxy_request member exists, this method will encapsulate
    # a raw HTTP request using the information in the proxy_request
    # and return a complete raw proxied request blob. If there is
    # no proxy_request defined for this object, this method will 
    # return nil.
    def to_raw_proxied
      return nil unless proxy_request
      pbody = to_raw()
      return proxy_request.to_raw(pbody)
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

pp [hstr, bstr, act, hdr]
      bstr = nil if bstr and bstr.empty? and hdr["Content-Length"].nil?

      if act.verb.to_s.upcase == "CONNECT"
        self.proxy_request = nil
        preq = self.class.new(act, hdr)
        capture(bstr)
        raise "multiple proxy CONNECT headers!" if self.proxy_request
        self.proxy_request = preq
      else
        self.action = act
        self.headers = hdr
        self.body = bstr
      end
      return self
    end

    def self.parse(str)
      return new().capture(str)
    end
  end


  # A class which encapsulates all the entities in a HTTP response
  # including the status header, general headers, and body.
  #
  # TODO: handle chunked encoding in capture and to_raw
  class Response < Struct.new(:status, :headers, :body)
    # Returns a raw HTTP response for this instance. Must have a status
    # element defined at a bare minimum.
    def to_raw(body=self.body)
      rsp = self
      raise "this response has no status element" unless s=rsp.status

      status = s.to_raw
      rsp.headers["Content-Length"] = rsp.body.to_s.size.to_s if rsp.body
      headers = (rsp.headers).to_raw_array.unshift(status)

      return "#{headers.join("\r\n")}\r\n\r\n#{req[:body]}"
    end

    # Parses a raw HTTP response into the current instance.
    def capture(str)
      raise "arg 0 must be a string" unless String === str
      hstr, bstr = str.split(/\s*\r?\n\r?\n/, 2)
      self.status, self.headers = ResponseHeaders.parse_full_headers(hstr)
      self.body = bstr
      return self
    end

    # Parses a raw HTTP response and returns a new Response object.
    def self.parse(str)
      return new().capture(str)
    end
  end
end

