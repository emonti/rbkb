require 'rbkb/cli'

# b64 converts strings or raw data to base-64 encoding.
class Rbkb::Cli::B64 < Rbkb::Cli::Executable
  def make_parser
    super()
    arg = @oparse
    arg.banner += " <data | blank for stdin>"

    arg.on("-l", "--length LEN", Numeric, "Output LEN chars per line") do |l|
        bail("length must be > 0") unless l > 0
        @opts[:len] = l
    end
  end

  def parse(*args)
    super(*args)
    parse_string_argument()
    parse_catchall()
  end

  def go(*args)
    super(*args)
    @stdout << @opts[:indat].b64(opts[:len]).chomp + "\n"
  end
end

