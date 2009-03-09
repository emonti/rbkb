require 'rbkb/cli'

# Repeats an argument N times
class Rbkb::Cli::Chars < Rbkb::Cli::Executable
  def make_parser
    super()
    @oparse.banner += " 100 A; # print 100 A's"
  end

  def parse(*args)
    super(*args)
    bail_args @argv.join unless @argv.size == 2
  end

  def go(*args)
    super(*args)
    @stdout << @argv[1] * @argv[0].to_i
  end
end

