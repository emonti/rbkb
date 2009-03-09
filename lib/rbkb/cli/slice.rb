require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
# Returns a slice from input. This is just a shell interface to a String.slice 
# operation.
class Rbkb::Cli::Slice < Rbkb::Cli::Executable

  def initialize(*args)
    super(*args)
    @opts[:last] ||= -1
  end

  def make_parser()
    super()
    add_std_file_opt(:indat)
    add_range_opts(:first, :last)
    arg = @oparse

    arg.banner += " start (no args when using -r or -x)"
  end


  def parse(*args)
    super(*args)
    @opts[:first] ||= @argv.shift

    unless(Numeric === @opts[:first] or /^-?\d+$/.match(@opts[:first]) )
      bail_args "invalid start length"
    end

    parse_catchall()

    @opts[:first] = @opts[:first].to_i
    @opts[:indat] ||= @stdin.read()
  end


  def go(*args)
    super(*args)
    @stdout << @opts[:indat][ @opts[:first] .. @opts[:last] ]
  end

end

