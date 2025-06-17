require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#
# b64 converts strings or raw data to base-64 encoding.
class Rbkb::Cli::B64 < Rbkb::Cli::Executable
  def make_parser
    super()
    arg = @oparse
    arg.banner += ' <data | blank for stdin>'

    add_std_file_opt(:indat)

    arg.on('-l', '--length LEN', Numeric, 'Output LEN chars per line') do |l|
      bail('length must be > 0') unless l > 0
      @opts[:len] = l
    end
  end

  def parse(*args)
    super(*args)
    parse_string_argument(:indat)
    parse_file_argument(:indat)
    parse_catchall
    @opts[:indat] ||= @stdin.read
  end

  def go(*args)
    super(*args)
    @stdout << @opts[:indat].b64(opts[:len]).chomp + "\n"
    self.exit(0)
  end
end
