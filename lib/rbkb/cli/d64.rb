require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
# d64 converts a base-64 encoded string back to its orginal form.
class Rbkb::Cli::D64 < Rbkb::Cli::Executable
  def make_parser
    super()
    @oparse.banner += " <data | blank for stdin>"
  end

  def parse(*args)
    super(*args)
    parse_string_argument(:indat)
    parse_catchall()
    @opts[:indat] ||= @stdin.read
  end

  def go(*args)
    super(*args)
    @stdout << @opts[:indat].d64
    self.exit(0)
  end
end

