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
    dat = opts[:indat].force_to_binary
    dat = dat[ @opts[:first] .. @opts[:last] ]
    dat ||= ""
    @stdout.puts( "%0.8x" % dat.force_to_binary.crc32 )
    self.exit(0)
  end
end


