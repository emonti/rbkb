# Author Eric Monti (emonti at matasano)
require 'optparse'

module RBkB
  module CommandLine
    # exits with a message on stderr
    def bail(msg)
      STDERR.puts msg if msg
      exit 1
    end

    # returns a OptionsParser object with blackbag standard options
    def bkb_stdargs(o=OptionParser.new, cfg=OPTS)
      o=OptionParser.new 
      o.banner = "Usage: #{File.basename $0} [options]"

      o.on("-h", "--help", "Show this message") do
        bail(o)
      end

      o.on("-v", "--version", "Show version and exit") do
        bail("Ruby BlackBag version #{RBkB::VERSION}")
      end
    end

    # returns a OptionsParser object with blackbag input options
    def bkb_inputargs(o=OptionParser.new, cfg=OPTS)
      o.on("-f", "--file FILENAME", 
      "Input from FILENAME") do |f|
        begin
          cfg[:indat] = File.read(f) 
        rescue 
          bail "File Error: #{$!}"
        end
      end

      return o
    end
  end
end

