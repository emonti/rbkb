require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#
# Reverses a hexdump back to raw data. Designed to work with hexdumps created
# by Unix utilities like 'xxd' as well as 'hexdump -C'.
class Rbkb::Cli::Dedump < Rbkb::Cli::Executable
  def initialize(*args)
    super(*args) {|this|
      this.opts[:len] ||= 16
      yield this if block_given?
    }
  end

  def make_parser()
    arg = super()
    arg.banner += " <input-file | blank for stdin>"

    arg.on("-l", "--length LEN", Numeric,
      "Bytes per line in hexdump (Default: #{@opts[:len]})") do |l|
        bail("Length must be greater than zero") unless (@opts[:len] = l) > 0
    end
    return arg
  end

  def parse(*args)
    super(*args)
    parse_file_argument(:indat)
    parse_catchall()
  end

  def go(*args)
    super(*args)

    # Default to standard input
    @opts[:indat] ||= @stdin.read()

    self.exit(1) unless((@opts[:len] ||= @opts[:indat].length) > 0)

    begin
      @opts[:indat].dehexdump( :len => @opts[:len], :out => @stdout)
    rescue
      bail "Error: #{$!}"
    end

    self.exit(0)
  end
end



