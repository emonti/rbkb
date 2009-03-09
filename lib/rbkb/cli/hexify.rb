#!/usr/bin/env ruby

require 'rbkb/cli'

# The hexify command converts a string or raw data to hex characters. 
# Input can be supplied via stdin, a string argument, or a file (with -f).
class Rbkb::Cli::Hexify < Rbkb::Cli::Executable
  def make_parser
    super()
    add_std_file_opt(:indat)
    arg = @oparse

    # Add local options
    arg.banner += " <data | blank for stdin>"

    arg.on("-l", "--length LEN", Numeric, "Output lines of LEN bytes") do |l|
      bail("Length must be greater than zero") unless (@opts[:len] = l) > 0
    end

    arg.on("-d", "--delim=DELIMITER", "DELIMITER between each byte") do |d|
      @opts[:delim] = d
    end

    arg.on("-p", "--prefix=PREFIX", "PREFIX before each byte") do |p|
      @opts[:prefix] = p
    end

    arg.on("-s", "--suffix=SUFFIX", "SUFFIX after each byte") do |s|
      @opts[:suffix] = s
    end
  end

  def parse(*args)
    super(*args)

    # blackbag-style space delimiter compatability
    if @argv[0] == "+" and @opts[:delim].nil?
      @opts[:delim]=" "
      @argv.shift
    end

    parse_string_argument(:indat)
    parse_catchall()
  end

  def go(*args)
    super(*args)

    # Default to standard input
    @opts[:indat] ||= @stdin.read() 

    indat = @opts.delete(:indat)
    len = @opts.delete(:len)

    self.exit(1) unless((len ||= indat.length) > 0)

    until (m = indat.slice!(0..len-1)).empty?
      @stdout << m.hexify(@opts)
      @stdout.puts((opts[:delim] and ! indat.empty?)? opts[:delim] : "\n")
    end
    self.exit(0)
  end
end

