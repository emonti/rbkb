require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/unhexify'

class TestCliUnhexify < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Unhexify
    super()
  end

  def test_string_arg
    assert_equal 0, go_with_args(%w(666f6f))
    assert_equal("foo", @stdout_io.string)
  end

  def test_string_arg_with_delim_arg
    assert_equal 0, go_with_args(%w(-d : 66:6f:6f))
    assert_equal("foo", @stdout_io.string)
  end

  def test_stdin
    @stdin_io.write("666f6f") ; @stdin_io.rewind
    assert_equal 0, go_with_args
    assert_equal("foo", @stdout_io.string)
  end

  def test_stdin_with_delim_default_allchars
    @stdin_io.write((0..255).map {|x| x.to_s(16)}.join(' ')); @stdin_io.rewind
    assert_equal 0, go_with_args
    assert_equal((0..255).map {|x| x.chr}.join, @stdout_io.string)
  end


  def test_file_input
    with_testfile do |fname, tf|
      tf.write "6865785f746573745f666f6f";  tf.close
      assert_equal 0, go_with_args(["-f", fname])
      assert_equal("hex_test_foo", @stdout_io.string)
    end
  end

end
