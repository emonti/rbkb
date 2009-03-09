require 'rbkb/cli'

# d64 converts a base-64 encoded string back to its orginal form.
class Rbkb::Cli::D64 < Rbkb::Cli::Executable
  def make_parser
    super()
    @oparse.banner += " <data | blank for stdin>"
  end

  def parse(*args)
    super(*args)
    parse_string_argument()
    parse_catchall()
  end

  def go(*args)
    super(*args)
    @stdout << @opts[:indat].d64
    self.exit(0)
  end
end

