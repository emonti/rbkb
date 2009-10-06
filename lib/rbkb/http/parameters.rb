module Rbkb::Http

  # The Parameters class is for handling named parameter values. This is a
  # stub base class from which to derive specific parameter parsers such as:
  #
  #   FormUrlencodedParams for request query string parameters and POST 
  #   content using application/www-form-urlencoded format.
  #
  #   MultiPartFormParams for POST content using multipart/form-data
  class Parameters < Array
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    def initialize(*args)
      _common_init(*args)
    end
    
    def get_all(k)
      self.select {|p| p[0] == k}
    end

    def get_all_values_for(k)
      self.get_all(k).collect {|p,v| v }
    end
    alias all_values_for get_all_values_for

    def get_param(k)
      self.find {|p| p[0] == k}
    end

    def get_value_for(k)
      if p=self.get_param(k)
        return p[1]
      end
    end
    alias get_param_value get_value_for
    alias value_for get_value_for

    def set_param(k, v)
      if p=self.get_param(k)
        p[1]=v
      else
        p << [k,v]
      end
      return [[k,v]]
    end

    def set_all_for(k, v)
      sel=self.get_all(k)
      if sel.empty?
        self << [k,v]
        return [[k,v]]
      else
        sel.each {|p| p[1] = v}
        return sel
      end
    end

    def delete_param(k)
      self.delete_if {|p| p[0] == k }
    end
  end

  class HeaderParams < Parameters
    def to_raw(quote_val=false)
      ret = ([nil] + self).map do |k,v| 
        if v 
          "#{k}=#{quote_val ? "\"#{v}\"" : v}"
        else 
          "#{k}" 
        end
      end.join("; ")
    end
    
    def capture(str)
      raise "arg 0 must be a string" unless str.is_a? String
      str.split(/\s*;\s*/).each do |p|
        var, val = p.split('=', 2)
        if val =~ /^(['"])(.*)\1$/
          val = $2
        end
        self << [var.strip, val]
      end
      return self
    end
  end
  
  
  # The FormUrlencodedParams class is for Parameters values in the 
  # form of 'q=foo&l=1&z=baz' as found in GET query strings and
  # application/www-form-urlencoded or application/x-url-encoded POST 
  # contents.
  class FormUrlencodedParams < Parameters
    def to_raw
      self.map do |k,v| 
        if v
          "#{k}=#{v}" 
        else 
          "#{k}"
        end
      end.join('&')
    end

    def capture(str)
      raise "arg 0 must be a string" unless str.is_a? String
      str.split('&').each do |p| 
        var,val = p.split('=',2)
        self << [var,val]
      end
      return self
    end
  end


  require 'strscan'
  
  # The MultipartFormParams class is for Parameters in POST data when using
  # the multipart/form-data content type. This is often used for file uploads.
  class MultipartFormParams < Parameters
    attr_accessor :boundary, :part_headers

    # You must specify a boundary somehow when instantiating a new MultipartFormParams
    # object. The
    def initialize(*args)
      _common_init(*args) do |this|
        yield this if block_given?
        this.boundary ||=
          ( this.opts[:boundary] || rand(0xffffffffffffffff).to_s(16).rjust(48,'-') )
      end
    end
    
    def to_raw
      ret = ""
      self.each_with_index do |p,i|
        name, value = p 
        ret << "--#{boundary.to_s}\n"
        hdrs = @part_headers[i]
        if cd = hdrs.get_parameterized_value("Content-Disposition")
          v, parms = cd
          parms.set_value_for("name", name) if name
          hdrs.set_parameterized_value("Content-Disposition", v, parms)
        else
          hdrs.set_value_for("Content-Disposition", "form-data; name=#{name}")
        end

        ret << hdrs.to_raw
        ret << "#{value}\n"
      end
      ret << "#{boundary}--"

    end

    def capture(str)
      raise "arg 0 must be a string" unless String === str
      @part_headers = []
      self.replace([])
      
      s = StringScanner.new(str)
      bound = /\-\-#{Regexp.escape(@boundary)}\r?\n/
      unless start=s.scan_until(bound) and start.index(@boundary)==2
        raise "unexpected start data #{start.inspect}"
      end
      
      while chunk = s.scan_until(bound)
        part = chunk[0,chunk.index(bound)].chomp
        phdr, body = part.split(/^\r?\n/, 2)
        head=Headers.parse(phdr)
        x, parms = head.get_parameterized_value('Content-Disposition')
        if parms and name=parms.get_value_for("name")
          @part_headers << head
          self << [name, body]
        else
          raise "invalid chunk at #{s.pos} bytes"
        end
      end
      unless str[s.pos..-1] =~ /^\-\-#{Regexp.escape(@boundary)}--(?:\r?\n|$)/
        raise "expected boundary terminator at #{s.pos}"
      end
      return self
    end
  end
end

