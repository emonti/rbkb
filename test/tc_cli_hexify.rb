require File.join(File.dirname(__FILE__), "test_helper.rb")
require 'pp'
require 'stringio'
require 'rbkb/cli/hexify'

Rbkb::Cli::TESTING = true

class TestCliHexify < Test::Unit::TestCase
  def setup
    @stdout_io = StringIO.new
    @stderr_io = StringIO.new
    @stdin_io  = StringIO.new
    @hexify = Rbkb::Cli::Hexify.new(
      :stdout => @stdout_io, 
      :stderr => @stderr_io,
      :stdin => @stdin_io
    )
  end

  def run_with_args(argv,status)
    @hexify.argv = argv
    assert_raise RuntimeError do
      @hexify.go
    end
    return @hexify.exit_status
  end

  def test_usage
    ret = run_with_args(["-h"], 1)
    assert_equal 1, ret
    assert_match(/^Usage: /, @stderr_io.string )
  end
end
