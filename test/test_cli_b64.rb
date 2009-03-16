require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/b64'

class TestCliB64 < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::B64
    super()
  end

  def test_basic_string_arg
    assert_equal 0, run_with_args(%w(fooby))
    assert_equal "Zm9vYnk=\n", @stdout_io.string
  end

  def test_stdin
    @stdin_io.write("fooby") ; @stdin_io.rewind
    assert_equal 0, run_with_args()
    assert_equal "Zm9vYnk=\n", @stdout_io.string
  end


  def test_length_arg
    assert_equal 0, run_with_args(%w(-l 2 fooby))
    assert_equal "Zm\n9v\nYn\nk=\n", @stdout_io.string
  end

  def test_bad_length_arg
    assert_equal 1, run_with_args(%w(-l -2 fooby))
    assert_match(/length must be > 0/, @stderr_io.string)
  end


end
