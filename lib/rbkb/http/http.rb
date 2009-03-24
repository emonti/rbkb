require 'rbkb'
require 'uri'

module Rbkb::Http

  # A generic cheat for Arrays containing named value pairs to act like Hash 
  # when using [] and []=
  class NamedValueArray < Array
    # Act like a hash with header names. Return the named header if a string
    # is supplied as the index argument.
    def [](*args)
      if args.size == 1 and (String === args[0] or Symbol === args[0])
        if h=find {|x| x[0] == args[0]}
          return h[1]
        end
      else
        super(*args)
      end
    end

    # Act like a hash with header names. Set the named header if a string
    # is supplied as the index argument.
    def []=(*args)
      if args.size > 1 and (String === args[0] or Symbol === args[0])
        if h=find {|x| x[0] == args[0]}
          h[1] = args[1]
        else
          self << args[0,2]
        end
      else
        super(*args)
      end
    end
  end

  # The Parameters object is for handling parameter lists in the form of
  # 'q=foo&l=1&z=baz' as often found in GET actions and POST data
  class Parameters < NamedValueArray
    def join_http_params
      self.map {|k,v| "#{k}=#{v}"}.join('&')
    end

    def self.parse(str)
      raise "arg 0 must be a string" unless String === str
      params = new
      str.split('&').each do |p| 
        var,val = p.split('=',2)
        params[var] = val
      end
      return params
    end
  end


  class Headers < NamedValueArray
    def join_http_headers
      self.map {|h,v| "#{h}: #{v}" }
    end

    def self.parse(str)
      raise "arg 0 must be a string" unless String === str
      headers = new()

      heads = str.split(/\s*\r?\n/)

      # pass interim parsed headers to a block if given
      yield(heads) if block_given?

      heads.each do |s| 
        h ,v = s.split(/\s*:\s*/, 2)
        headers[h]=v
      end
      return headers
    end
  end

  class RequestHeaders < Headers
    def self.parse(str, has_action=true)
      action = nil
      headers = super(str) do |heads|
        action = RequestAction.parse(heads.shift) if has_action
      end
      return [action, headers]
    end
  end

  class ResponseHeaders < Headers
    def self.parse(str, has_status=true)
      status = nil
      headers = super(str) do |heads|
        status = ResponseStatus.parse(heads.shift) if has_status
      end
      return [status, headers]
    end
  end

  class ResponseStatus < Struct.new(:version, :code, :text)
    def join_http_status
      [version, code, text].join(" ")
    end

    def self.parse(str)
      raise "arg 0 must be a string" unless String === str
      unless m=/^([^\s]+)\s+(\d+)(?:\s+(.*))?$/.match(str)
        raise "invalid action #{str.inspect}"
      end
      return new(m[1], m[2].to_i, m[3])
    end
  end

  class RequestAction < Struct.new(:verb,:uri,:version)
    def join_http_action
      ary = [ verb, uri ]
      ary << version if version
      ary.join(" ")
    end

    def self.parse(str)
      raise "arg 0 must be a string" unless String === str
      unless m=/^([^\s]+)\s+([^\s]+)(?:\s+([^\s]+))?\s*$/.match(str)
        raise "invalid action #{str.inspect}"
      end

      return new(m[1], URI.parse(m[2]), m[3])
    end
  end


  class Request < Struct.new(:action, :headers, :body, :proxy_request)
    def request_parameters
      if q = action.uri.query
        Parameters.parse(q)
      end
    end

    def join_raw_http_request
      req=self
      raise "this request has no action element" unless a=req.action

      action = a.join_http_action
      req.headers["Content-Length"] = req.body.to_s.size.to_s if req.body
      headers = (req.headers).join_http_headers.unshift(action)

      return "#{headers.join("\r\n")}\r\n\r\n#{req[:body]}"
    end

    def self.parse(str)
      raise "arg 0 must be a string" unless String === str
      head, body = str.split(/\s*\r?\n\r?\n/, 2)
      action, headers = RequestHeaders.parse(head)

      body = nil if body.empty? and headers["Content-Length"].nil?

      if action.verb.upcase == "CONNECT"
        req = parse(body)
        raise "multiple proxy CONNECT headers!" if req.proxy_request
        req.proxy_request = new(action, headers)
        return req
      else
        return new(action, headers, body)
      end
    end
  end


  class Response < Struct.new(:status, :headers, :body)
    def join_raw_http_response
      rsp = self
      raise "this response has no status element" unless s=rsp.status

      status = s.join_http_status
      rsp.headers["Content-Length"] = rsp.body.to_s.size.to_s if rsp.body
      headers = (rsp.headers).join_http_headers.unshift(status)

      return "#{headers.join("\r\n")}\r\n\r\n#{req[:body]}"
    end

    def self.parse(str)
      raise "arg 0 must be a string" unless String === str
      head, body = str.split(/\s*\r?\n\r?\n/, 2)
      status, headers = ResponseHeaders.parse(head)
      return new(status, headers, body)
    end
  end
end
