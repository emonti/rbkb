require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#
# searches for a binary string in input. string can be provided 'hexified'
class Rbkb::Cli::Bgrep < Rbkb::Cli::Executable
  def initialize(*args)
    super(*args) do |this|
      this.opts[:start_off] ||= 0
      this.opts[:end_off] ||= -1
      this.opts[:include_fname] ||= true
    end
  end

  def make_parser
    arg = super()
    arg.banner += " <search> <file | blank for stdin>"

    arg.on("-x", "--[no-]hex", "Search for hex (default: false)") do |x|
      @opts[:hex] = x
    end

    arg.on("-r", "--[no-]regex", "Search for regex (default: false)") do |r|
      @opts[:rx] = r
    end

    arg.on("-a", "--align=BYTES", Numeric,
           "Only match on alignment boundary") do |a|
      @opts[:align] = a
    end

    arg.on("-n", "--[no-]filename",
           "Toggle filenames. (Default: #{@opts[:include_fname]})") do |n|
      @opts[:include_fname] = n
    end
    return arg
  end


  def parse(*args)
    super(*args)

    bail "need search argument" unless @find = @argv.shift

    if @opts[:hex] and @opts[:rx]
      bail "-r and -x are mutually exclusive"
    end

    # ... filenames vs. stdin will be parsed in 'go'
  end

  def go(*args)
    super(*args)

    if @opts[:hex]
      bail "you specified -x for hex and the subject isn't" unless @find.ishex?
      @find = @find.unhexify
    elsif @opts[:rx]
      @find = Regexp.new(@find, Regexp::MULTILINE)
    end

    if fname = @argv.shift
      dat = do_file_read(fname)
      fname = nil unless @argv[0] # only print filenames for multiple files
    else
      dat = @stdin.read
    end

    loop do
      dat.bgrep(@find, @opts[:align]) do |hit_start, hit_end, match|
        @stdout.write "#{fname}:" if fname and @opts[:include_fname]

        @stdout.write("%0.8x:%0.8x:b:#{match.inspect}\n" %[hit_start, hit_end])
      end

      break unless fname=@argv.shift
      dat = do_file_read(fname)
    end
    self.exit(0)
  end
end

