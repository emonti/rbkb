require 'rbkb/cli'

# d64 converts a base-64 encoded string back to its orginal form.
class Rbkb::Cli::D64 < Rbkb::Cli::Executable
  def make_parser
    arg = super()
    arg.banner += " <data | blank for stdin>"
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
    @stdout << @opts[:indat].d64
    self.exit(0)
  end
end

