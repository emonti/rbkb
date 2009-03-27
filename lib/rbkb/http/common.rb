module Rbkb::Http
  DEFAULT_HTTP_VERSION = "HTTP/1.1"

  module CommonInterface
    # This provides a common method for use in 'initialize' to slurp in 
    # opts parameters and optionally capture a raw blob. This method also 
    # accepts a block to which it yields 'self'
    def _common_init(raw=nil, opts=nil)
      self.opts = opts
      yield self if block_given?
      capture(raw) if raw
      return self
    end

    # Implements a common interface for an opts hash which is stored internally
    # as the class variable @opts.
    #
    # The opts hash is designed to contain various named values for 
    # configuration, etc. The values and names are determined entirely
    # by the class that uses it.
    def opts
      @opts
    end

    # Implements a common interface for setting a new opts hash containing
    # various named values for configuration, etc. This also performs a 
    # minimal sanity check to ensure the object is a Hash.
    def opts=(o=nil)
      raise "opts must be a hash" unless (o ||= {}).is_a? Hash
      @opts = o
    end
  end


  # A generic cheat for an Array of named value pairs to pretend to 
  # be like Hash when using [] and []=
  class NamedValueArray < Array

    # Act like a hash with named values. Return the named value if a string
    # or Symbol is supplied as the index argument.
    #
    # Note, this doesn't do any magic with String / Symbol conversion.
    def [](*args)
      if args.size == 1 and (String === args[0] or Symbol === args[0])
        if h=find {|x| x[0] == args[0]}
          return h[1]
        end
      else
        super(*args)
      end
    end

    # Act like a hash with named values. Set the named value if a String
    # or Symbol is supplied as the index argument.
    #
    # Note, this doesn't do any magic with String / Symbol conversion.
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

    def delete_key(key)
      delete_if {|x| x[0] == key }
    end
  end

end
