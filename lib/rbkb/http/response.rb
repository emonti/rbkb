
module Rbkb::Http
  # A Response encapsulates all the entities in a HTTP response,
  # including the status header, general headers, and body.
  class Response < Base
    attr_accessor :status

    alias first_entity status
    alias first_entity= status=

    # Returns a raw HTTP response for this instance. Must have a status
    # element defined at a bare minimum.
    def to_raw(raw_body=nil)
      raise "this response has no status" unless first_entity()
      self.headers ||= default_headers_obj()
      self.body = raw_body if raw_body

      if do_chunked_encoding?(@headers)
        unless @body.is_a? ChunkedBody
          @body = ChunkedBody.new(@body, @body.opts)
        end
        @headers.delete_header("Content-Length")
      elsif not opts[:ignore_content_length]
        unless @body.is_a? BoundBody
          @body = BoundBody.new(@body, @body.opts)
        end
        @headers.delete_header("Transfer-Encoding")
      else
        @body = Body.new(@body, @body.opts)
      end
      @body.base = self

      yield(self) if block_given?

      bstr = @body.to_raw
      hdrs = @headers.to_raw_array.unshift(self.first_entity.to_raw)
      return "#{hdrs.join("\r\n")}\r\n\r\n#{bstr}"
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

    # Indicates whether to use chunked encoding based on presence of 
    # the "Transfer-Encoding: chunked" header or the :ignore_chunked_encoding
    # opts parameter.
    def do_chunked_encoding?(hdrs=@headers)
      ( (not @opts[:ignore_chunked_encoding]) and 
        (hdrs.get_header_value("Transfer-Encoding").to_s =~ /(?:^|\W)chunked(?:\W|$)/) )
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
  end
end
