require 'rbkb'
require 'optparse'

module Rbkb
  module Cli
    # Rbkb::Cli::Executable is an abstract class for creating command line
    # executables using the Ruby Black Bag framework.
    class Executable
      attr_accessor :stdout, :stderr, :stdin, :argv, :opts, :oparse

      # Instantiates a new Executable object.
      #
      # The 'param' argument is a named value hash. The following keys are
      # significant:
      #
      #  :argv   - An array of cli arguments (default ARGV)
      #
      #  :stdout, - Unit tests
      #  :stderr, 
      #  :stdin
      #
      #  :opts    - executable/function options for use when running 'go'
      #
      # The above keys are deleted from the 'param' hash and stored as instance
      # variables with attr_accessors.  All other parameters are ignored.
      def initialize(param={})
        @argv   ||= param.delete(:argv) || ARGV
        @stdout ||= param.delete(:stdout) || STDOUT
        @stderr ||= param.delete(:stderr) || STDOUT
        @stdin  ||= param.delete(:stdin) || STDIN
        @opts   ||= param.delete(:opts) || {}
        make_parser()
        yield self if block_given?
      end

      # Wrapper for Kernel.exit() so we can unit test cli tools
      def exit(ret)
        if defined? Rbkb::Cli::TESTING
          return(ret)
        else
          Kernel.exit(ret)
        end
      end

      # This method exits with a message on stderr
      def bail(msg)
        @stderr.puts msg if msg
        self.exit(1)
      end

      # This method wraps a 'bail' with a basic argument error mesage and hint
      # for the '-h or --help' flag
      # The 'arg_err'  parameter is a string with the erroneous arguments
      def bail_args(arg_err)
        bail "Error: bad arguments - #{arg_err}\n  Hint: Use -h or --help"
      end

      # Prepares an OptionsParser object with blackbag standard options
      # This is called from within initialize() and should be overridden in
      # inherited classes to add additional OptionParser-based parsers.
      #
      # See parse for actual parsing.
      def make_parser
        @oparse ||= OptionParser.new 
        @oparse.banner = "Usage: #{File.basename $0} [options]"

        @oparse.on("-h", "--help", "Show this message") do
          bail(@oparse)
        end

        @oparse.on("-v", "--version", "Show version and exit") do
          bail("Ruby BlackBag version #{Rbkb::VERSION}")
        end

        return @oparse
      end

      # Implements a basic input file argument. 
      # (Used commonly throughout several executables)
      def add_std_file_arg(args=@oparse)
        args.on("-f", "--file FILENAME", "Input from FILENAME") do |f|
          begin
            @opts[:indat] = File.read(f) 
          rescue 
            bail "File Error: #{$!}"
          end
        end
        return args
      end

      # Abstract argument parser. Override this method with super() from 
      # inherited executables. The base method just calls OptionParser.parse!
      # on the internal @oparse object.
      def parse
        # parse flag arguments
        @oparse.parse!(@argv) rescue bail_args($!)
        @parsed=true

        # overriding class implements additional arguments from here
      end
      
      def go(argv=nil)
        @argv = argv if argv
        parse unless @parsed
        # overriding class implements actual functionality from here
      end

      def self.run(opts={})
        new(opts).go
      end
    end
  end
end

