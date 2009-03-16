require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/d64'

class TestCliD64 < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::D64
    super()
  end

  def test_basic_string_arg
    assert_equal 0, run_with_args(%w(Zm9vYnk=))
    assert_equal "fooby", @stdout_io.string
  end

  def test_stdin
    @stdin_io.write "Zm9vYnk=" ; @stdin_io.rewind
    assert_equal 0, run_with_args()
    assert_equal "fooby", @stdout_io.string
  end
end
