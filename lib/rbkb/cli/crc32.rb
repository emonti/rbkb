require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#
# crc32 returns a crc32 checksum in hex from stdin or a file
class Rbkb::Cli::Crc32 < Rbkb::Cli::Executable
  def initialize(*args)
    super(*args)
    @opts[:first] ||= 0
    @opts[:last]  ||= -1
  end

  def make_parser()
    arg = super()
    arg.banner += " [filename]"
    add_std_file_opt(:indat)
    add_range_opts(:first, :last)
  end

  def parse(*args)
    super(*args)
    parse_file_argument(:indat)
    parse_catchall()
  end

  def go(*args)
    super(*args)
    @opts[:indat] ||= @stdin.read()
    @stdout.puts( "%0.8x" % @opts[:indat][ @opts[:first] .. @opts[:last] ].crc32 )
    self.exit(0)
  end
end


