
module Rbkb
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
  end

end
