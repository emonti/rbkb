require 'stringio'

module Rbkb::Http
  class Body < String
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    attr_reader :expect_length

    def initialize(str=nil, opts=nil)
      self.opts = opts
      if Body === str
        self.replace(str)
        @opts = str.opts.merge(@opts)
      elsif String === str 
        super(str)
      else
        super()
      end

      yield(self) if block_given?
    end

    # The capture method is used when parsing HTTP requests/responses.
    # This can and probably should be overridden in derived classes.
    def capture(str)
      yield(str) if block_given?
      self.data=(str)
    end

    # The to_raw method is used when writing HTTP requests/responses.
    # This can and probably should be overridden in derived classes.
    def to_raw
      (block_given?) ? yield(self.data) : self.data
    end

    attr_reader :base

    def base=(b)
      if b.nil? or b.is_a? Base
        @base = b
      else
        raise "base must be a Response or Request object or nil" 
      end
    end

    def data
      self
    end

    # Sets internal raw string data without any HTTP decoration.
    def data=(str)
      self.replace(str.to_s)
    end

    # Returns the content length from the HTTP base object if
    # there is one and content-length is available.
    def get_content_length
      @base.content_length if @base
    end

    # This method will non-destructively reset the capture state on this object.
    # It is non-destructive in that it will not affect existing captured data 
    # if present.
    def reset_capture
      @expect_length = nil
      @base.reset_capture() if @base and @base.capture_complete?
    end

    # This method will destructively reset the capture state on this object.
    # This method is destructive in that it will clear any previously captured
    # data.
    def reset_capture!
      reset_capture()
      self.data=""
    end

    def capture_complete?
      not @expect_length
    end
  end


  # BoundBody is designed for handling an HTTP body when using the usual
  # "Content-Length: NNN" HTTP header.
  class BoundBody < Body

    # This method may throw :expect_length with one of the following values
    # to indicate certain content-length conditions:
    #
    #   > 0 :   Got incomplete data in this capture. The object expects
    #           capture to be called again with more body data.
    #
    #   < 0 :   Got more data than expected, the caller should truncate and 
    #           handle the extra data in some way. Note: Calling capture again
    #           on this instance will start a fresh body capture.
    #
    # Caller can also detect the above conditions by checking the expect_length 
    # attribute but should still be prepared handle the throw().
    #
    #  0/nil:  Got exactly what was expected. Caller can proceed with fresh
    #          captures on this or other Body objects.
    #
    # See also reset_capture and reset_capture!
    def capture(str)
      raise "arg 0 must be a string" unless String === str

      # Start fresh unless we're expecting more data
      self.data="" unless @expect_length and @expect_length > 0

      if not clen=get_content_length()
        raise "content-length is unknown. aborting capture"
      else
        @expect_length = clen - (self.size + str.size)
        self << str[0, clen - self.size]
        if @expect_length > 0
          throw(:expect_length, @expect_length)
        elsif @expect_length < 0
          throw(:expect_length, @expect_length)
        else
          reset_capture()
        end
      end
      return self
    end

    def to_raw(*args)
      if @base
        @base.headers.set_header("Content-Length", self.size)
      end
      super(*args)
    end
  end


  # ChunkedBody is designed for handling an HTTP body when using a
  # "Transfer-Encoding: chunked" HTTP header.
  class ChunkedBody < Body
    DEFAULT_CHUNK_SIZE = 2048

    # Throws :expect_length with 'true' when given incomplete data and expects 
    # to be called again with more body data to parse. 
    #
    # The caller can also detect this condition by checking the expect_length 
    # attribute but must still handle the throw().
    #
    # See also reset_capture and reset_capture!
    def capture(str)
      # chunked encoding is gross...
      if @expect_length
        sio = StringIO.new(@last_chunk.to_s + str)
      else
        sio = StringIO.new(str)
        self.data=""
      end
      @last_chunk = nil

      @expect_length = true
      while not sio.eof?
        unless m=/^([a-fA-F0-9]+)\s*(;[[:print:]\s]*)?\r?\n$/.match(line=sio.readline)
          raise "invalid chunk at #{line.chomp.inspect}"
        end
        if (chunksz = m[1].hex) == 0
          @expect_length = false
          # XXX ignore Trailer headers
          break
        end

        if ( (not sio.eof?) and 
             (chunk=sio.read(chunksz)) and 
             chunk.size == chunksz and 
             (not sio.eof?) and (extra = sio.readline) and
             (not sio.eof?) and (extra << sio.readline)
           )
          if extra =~ /^\r?\n\r?\n$/
            yield(chunk) if block_given?
            self << chunk
          else
            raise "expected CRLF"
          end
        else
          @last_chunk = line + chunk.to_s + extra.to_s
          break
        end
      end
      throw(:expect_length, @expect_length) if @expect_length
      return self
    end


    def to_raw(csz=nil)
      csz ||= (@opts[:output_chunk_size] || DEFAULT_CHUNK_SIZE)
      unless csz.kind_of? Integer and csz > 0
        raise "chunk size must be an integer >= 1"
      end

      out=[]
      i=0
      while i <= self.size
        chunk = self[i, csz]
        out << "#{chunk.size.to_s(16)}\r\n#{chunk}\r\n\r\n"
        yield(self, out.last) if block_given?
        i+=csz
      end
      out << "0\r\n"
      yield(self, out.last) if block_given?
      return out.join
    end
  end
end

