require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
# urldec converts a url percent-encoded string back to its raw form.
# Input can be supplied via stdin, a string argument, or a file (with -f).
# (url percent-encoding is just fancy hex encoding)
class Rbkb::Cli::Urldec < Rbkb::Cli::Executable
  def make_parser()
    super()
    add_std_file_opt(:indat)
    arg = @oparse
    arg.banner += " <data | blank for stdin>"

    arg.on("-p", "--[no-]plus", "Convert '+' to space (default: true)") do |p|
      @opts[:noplus] = (not p)
    end
  end

  def parse(*args)
    super(*args)
    parse_string_argument(:indat)
    parse_catchall()
  end

  def go(*args)
    super(*args)
    # Default to standard input
    @opts[:indat] ||= @stdin.read()
    @stdout << @opts[:indat].urldec(:noplus => @opts[:noplus])
  end
end

