require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#
# urlenc converts a string or raw data to a url percent-encoded string
# Input can be supplied via stdin, a string argument, or a file (with -f).
# (url percent-encoding is just fancy hex encoding)
class Rbkb::Cli::Urlenc < Rbkb::Cli::Executable
  def make_parser()
    super()
    add_std_file_opt(:indat)
    arg = @oparse
    arg.banner += " <data | blank for stdin>"

    arg.on("-p", "--[no-]plus",
           "Convert spaces to '+' (default: false)") do |p|
      @opts[:plus] = p
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
    @stdout << @opts[:indat].urlenc(:plus => @opts[:plus]) + "\n"
    self.exit(0)
  end
end
