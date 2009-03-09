require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
# unhexify converts a string of hex bytes back to raw data. Input can be 
# supplied via stdin, a hex-string argument, or a file containing hex (use -f).
class Rbkb::Cli::Unhexify < Rbkb::Cli::Executable
  def make_parser
    super()
    add_std_file_opt(:indat)
    arg = @oparse

    #----------------------------------------------------------------------
    # Add local options
    arg.banner += " <data | blank for stdin>"

    arg.on("-d", "--delim DELIMITER", 
           "DELIMITER regex between hex chunks") do |d|
        @opts[:delim] = Regexp.new(d.gsub('\\\\', '\\'))
    end
  end

  def parse(*args)
    super(*args)

    # default string arg
    if @opts[:indat].nil? and a=@argv.shift
      @opts[:indat] = a.dup 
    end

    # catchall
    bail_args @argv.join(' ') if ARGV.length != 0 
  end

  def go(*args)
    super(*args)

    # Default to standard input
    @opts[:indat] ||= @stdin.read() 

    @opts[:indat].delete!("\r\n")
    @opts[:delim] ||= /\s*/

    unless out = @opts[:indat].unhexify(@opts[:delim])
      bail "Error: Failed parsing as hex"
    end

    @stdout << out

    self.exit(0)
  end
end

