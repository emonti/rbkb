require File.join(File.dirname(__FILE__), "test_helper.rb")
require 'rbkb/cli/hexify'

Rbkb::Cli::TESTING = true

class TestCliHexify < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Hexify
    super()
  end

  def test_string_arg
    assert_equal 0, go_with_args(%w(foo))
    assert_equal("666f6f\n", @stdout_io.string)
  end

  def test_length_argument
    assert_equal 0, go_with_args(%w(-l 1 foo))
    assert_equal("66\n6f\n6f\n", @stdout_io.string)
  end

  def test_bad_length_arguments
    assert_equal 1, go_with_args(%w(-l 0 foo), 1)
    assert_match(/must be greater than zero/, @stderr_io.string)
    assert_equal 1, go_with_args(%w(-l -1 foo), 1)
    assert_match(/must be greater than zero/, @stderr_io.string)
  end

  def test_string_arg_with_plus
    assert_equal 0, go_with_args(%w(+ foo))
    assert_equal("66 6f 6f\n", @stdout_io.string)
  end

  def test_string_arg_with_delim
    assert_equal 0, go_with_args(%w(-d : foo))
    assert_equal("66:6f:6f\n", @stdout_io.string)
  end

  def test_string_arg_with_prefix
    assert_equal 0, go_with_args(%w(-p : foo))
    assert_equal(":66:6f:6f\n", @stdout_io.string)
  end

  def test_string_arg_with_suffix
    assert_equal 0, go_with_args(%w(-s : foo))
    assert_equal("66:6f:6f:\n", @stdout_io.string)
  end

  def test_stdin
    @stdin_io.write("foo") ; @stdin_io.rewind
    assert_equal 0, go_with_args
    assert_equal("666f6f\n", @stdout_io.string)
  end

  def test_file_input
    with_testfile do |fname, tf| 
      tf.write "hex_test_foo";  tf.close
      assert_equal 0, go_with_args(["-f", fname])
      assert_equal("6865785f746573745f666f6f\n", @stdout_io.string)
    end
  end

end
