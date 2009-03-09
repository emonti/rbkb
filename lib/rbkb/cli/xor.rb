#!/usr/bin/env ruby
require 'rbkb/cli'

# Repeating string xor. Takes input from a string, stdin, or a file (-f).
class Rbkb::Cli::Xor < Rbkb::Cli::Executable
  def make_parser()
    super()
    add_std_file_opt(:indat)
    arg = @oparse
    arg.banner += " -k|-s <key> <data | stdin>"

    arg.separator "  Key options (you must specify one of the following):"
    arg.on("-s", "--strkey STRING", "xor against STRING")  do |s|
        bail "only one key option can be specified with -s or -x" if @opts[:key]
        @opts[:key] = s
    end

    arg.on("-x", "--hexkey HEXSTR", "xor against binary HEXSTR") do |x|
        bail "only one key option can be specified with -s or -x" if @opts[:key]
        x.sub!(/^0[xX]/, '')
        bail "Unable to parse hex string" unless @opts[:key] = x.unhexify
    end
    return arg
  end

  def parse(*args)
    super(*args)
    bail("You must specify a key with -s or -x\n#{@oparse}") unless @opts[:key]
    parse_string_argument(:indat)
    parse_catchall()
  end

  def go(*args)
    super(*args)
    @opts[:indat] ||= @stdin.read
    @stdout << @opts[:indat].xor(@opts[:key])
    self.exit(0)
  end
end

