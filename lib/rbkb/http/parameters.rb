module Rbkb::Http

  # The Parameters class is for handling named parameter values in the 
  # form of 'q=foo&l=1&z=baz' as found in GET action queries and
  # www-form-urlencoded POST body data
  class Parameters < NamedValueArray
    include CommonInterface

    def self.parse(str)
      new().capture(str)
    end

    def initialize(*args)
      _common_init(*args)
    end

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

