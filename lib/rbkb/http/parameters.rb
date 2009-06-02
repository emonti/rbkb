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

    def get_param(k)
      self.find {|p| p[0] == k}
    end

    def get_value_for(k)
      if v=self.get(k)
        return v[1]
      end
    end

    def get_all_values_for(k)
      self.get_all(k).map {|p,v| v }
    end

    def set_param(k, v)
      if p=self.get_param(k)
        p[1]=v
      else
        p << 
      end
      return v
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

  # The FormUrlencodedParams class is for Parameters values in the 
  # form of 'q=foo&l=1&z=baz' as found in GET query strings and
  # application/www-form-urlencoded or application/x-url-encoded POST 
  # contents.
  class FormUrlencodedParams < Parameters
    def to_raw
      self.map {|k,v| "#{k}=#{v}"}.join('&')
    end

    def capture(str)
      raise "arg 0 must be a string" unless String === str
      str.split('&').each do |p| 
        var,val = p.split('=',2)
        self << [var,val]
      end
      return self
    end
  end


  # The MultipartFormParams class is for Parameters in POST data when using
  # the multipart/form-data content type. This is often used for file uploads.
  class MultipartFormParams < Parameters
    def to_raw
      self.map {|k,v| "#{k}=#{v}"}.join('&')
    end

    def capture(str)
      raise "arg 0 must be a string" unless String === str
      str.split('&').each do |p| 
        var,val = p.split('=',2)
        self << [var,val]
      end
      return self
    end
  end
end

