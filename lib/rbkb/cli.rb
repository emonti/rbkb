require 'rbkb'
require 'optparse'

# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
module Rbkb::Cli

  # Rbkb::Cli::Executable is an abstract class for creating command line
  # executables using the Ruby Black Bag framework.
  class Executable

    def self.run(param={})
      new(param).go
    end

    attr_accessor :stdout, :stderr, :stdin, :argv, :opts, :oparse
    attr_reader   :exit_status

    # Instantiates a new Executable object.
    #
    # The 'param' argument is a named value hash. The following keys are
    # significant:
    #
    #  :argv   - An array of cli arguments (default ARGV)
    #  :opts    - executable/function options for use when running 'go'
    #  :stdout, - IO redirection (mostly for unit tests)
    #  :stderr,   
    #  :stdin
    #
    #
    # The above keys are deleted from the 'param' hash and stored as instance
    # variables with attr_accessors.  All other parameters are ignored.
    def initialize(param={})
      @argv   ||= param.delete(:argv) || ARGV
      @stdout ||= param.delete(:stdout) || STDOUT
      @stderr ||= param.delete(:stderr) || STDERR
      @stdin  ||= param.delete(:stdin) || STDIN
      @opts   ||= param.delete(:opts) || {}
      @parser_got_range=nil
      yield self if block_given?
      make_parser()
    end


    # Wrapper for Kernel.exit() so we can unit test cli tools
    def exit(ret)
      @exit_status = ret
      if defined? Rbkb::Cli::TESTING
        throw(((ret==0)? :exit_zero : :exit_err), ret)
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
        @stdout.puts("Ruby BlackBag version #{Rbkb::VERSION}")
        self.exit(0)
      end

      return @oparse
    end


    # Abstract argument parser. Override this method with super() from 
    # inherited executables. The base method just calls OptionParser.parse!
    # on the internal @oparse object.
    def parse
      # parse flag arguments
      @oparse.parse!(@argv) rescue(bail_args($!))
      @parsed=true

      # the overriding class may implement additional arguments from here
    end
    

    # Abstract 'runner'. Override this method with super() from inherited
    # executables. The base method just slurps in an optional argv and
    # runs 'parse' if it hasn't already
    def go(argv=nil)
      @exit_status = nil
      @argv = argv if argv 

      parse

      # the overriding class implements actual functionality beyond here
    end


    private

    # Wraps a file read with a standard bail error message
    def do_file_read(f)
      File.read(f) rescue(bail "File Read Error: #{$!}")
    end


    # Implements a basic input file argument. File reading is handled
    # by do_file_read().
    #
    # Takes one argument, which is the @opts hash keyname to store
    # the file data into.
    # (Used commonly throughout several executables)
    def add_std_file_opt(inkey)
      @oparse.on("-f", "--file FILENAME", "Input from FILENAME") do |f|
        @opts[inkey] = do_file_read(f)
      end
      return @oparse
    end


    # Implements numeric and hex range options via '-r' and '-x'
    #
    # Takes two arguments which are the @opts hash key names for
    # first and last parameters.
    #
    # (Used commonly throughout several executables)
    def add_range_opts(fkey, lkey)
      @oparse.on("-r", "--range=START[:END]", 
                 "Start and optional end range") do |r|

        raise "-x and -r are mutually exclusive" if @parser_got_range
        @parser_got_range=true

        unless m=/^(-?[0-9]+)(?::(-?[0-9]+))?$/.match(r)
          raise "invalid range #{r.inspect}"
        end

        @opts[fkey] = $1.to_i
        @opts[lkey] = $2.to_i if $2
      end

      @oparse.on("-x", "--hexrange=START[:END]", 
                 "Start and optional end range in hex") do |r|

        raise "-x and -r are mutually exclusive" if @parser_got_range
        @parser_got_range=true

        unless m=/^(-?[0-9a-f]+)(?::(-?[0-9a-f]+))?$/i.match(r)
          raise "invalid range #{r.inspect}"
        end

        @opts[fkey] = 
          if ($1[0,1] == '-')
            ($1[1..-1]).hex_to_num * -1
          else
            $1.hex_to_num
          end

        if $2
          @opts[lkey] = 
            if($2[0,1] == '-')
              $2[1..-1].hex_to_num * -1
            else
              $2.hex_to_num
            end
        end
      end
    end


    # Conditionally parses a string argument. Uses 'key' to first check for 
    # then store it in @opts hash if it is not yet there.
    # (Used commonly throughout several executables)
    def parse_string_argument(key)
      if @opts[key].nil? and s=@argv.shift
        @opts[key] = s.dup 
      end
    end


    # Conditionally parses a file argument. Uses 'key' to first check for 
    # then store it in @opts hash if it is not yet there.
    # (Used commonly throughout several executables)
    def parse_file_argument(key)
      if @opts[key].nil? and f=@argv.shift
        @opts[key] = do_file_read(f)
      end
    end

    # For use at the end of a parser - calls bail_args with remaining
    # arguments if there are extra arguments.
    # (Used commonly throughout several executables)
    def parse_catchall
      bail_args(@argv.join(' ')) if(@argv.length != 0)
    end

  end
end

