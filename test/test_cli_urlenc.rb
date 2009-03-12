require File.join(File.dirname(__FILE__), "test_helper.rb")
require 'rbkb/cli/urlenc'

class TestCliUrlenc < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Urlenc
    super()
  end

  def test_basic_string_arg
    assert_equal 0, run_with_args(["foo"])
    assert_equal "foo\n", @stdout_io.string
  end

  def test_basic_string_arg_space_default
    assert_equal 0, run_with_args(["fo o"])
    assert_equal "fo%20o\n", @stdout_io.string
  end

  def test_basic_string_arg_space_with_p
    assert_equal 0, run_with_args(["-p", "fo o"])
    assert_equal "fo+o\n", @stdout_io.string
  end

  def test_basic_string_arg_space_with_plus
    assert_equal 0, run_with_args(["--plus", "fo o"])
    assert_equal "fo+o\n", @stdout_io.string
  end

  def test_basic_string_arg_space_with_noplus
    assert_equal 0, run_with_args(["--no-plus", "fo o"])
    assert_equal "fo%20o\n", @stdout_io.string
  end


end
