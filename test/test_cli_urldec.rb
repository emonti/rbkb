require File.join(File.dirname(__FILE__), "test_helper.rb")
require 'rbkb/cli/urldec'

class TestCliUrldec < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Urldec
    super()
  end

  def test_basic_string_arg
    assert_equal 0, run_with_args(["foo"])
    assert_equal "foo", @stdout_io.string
  end

  def test_basic_string_arg_with_space
    assert_equal 0, run_with_args(["f%20oo"])
    assert_equal "f oo", @stdout_io.string
  end

  def test_basic_string_arg_with_space_plus
    assert_equal 0, run_with_args(["f+oo"])
    assert_equal "f oo", @stdout_io.string
  end

  def test_basic_string_arg_with_space_plus_p_arg
    assert_equal 0, run_with_args(["-p", "f+oo"])
    assert_equal "f oo", @stdout_io.string
  end

  def test_basic_string_arg_with_space_plus_plus_arg
    assert_equal 0, run_with_args(["--plus", "f+oo"])
    assert_equal "f oo", @stdout_io.string
  end

  def test_basic_string_arg_with_space_plus_noplus_arg
    assert_equal 0, run_with_args(["--no-plus", "f+oo"])
    assert_equal "f+oo", @stdout_io.string
  end



end
