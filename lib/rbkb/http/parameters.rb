module Rbkb::Http

  # The Parameters class is for handling named parameter values. This is a
  # stub base class from which to derive specific parameter parsers such as:
  #
  #   FormUrlencodedParams for request query string parameters and POST 
  #   content using application/www-form-urlencoded format.
  #
  #   MultiPartFormParams for POST content using multipart/form-data
  class Parameters < NamedValueArray
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    def initialize(*args)
      _common_init(*args)
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
        self[var] = val
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
        self[var] = val
      end
      return self
    end
  end
end

