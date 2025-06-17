require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/xor'

class TestCliXor < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Xor
    super()

    @tst_dat = "my secrets are very secret"
    @tst_key_str = "sneaky"
    @tst_key_hex = "736e65616b79"
    @tst_xored = "\036\027E\022\016\032\001\v\021\022K\030\001\vE\027\016\v\nN\026\004\b\v\026\032"
  end

  def test_string_arg_str_key_s_flag
    assert_equal 0, go_with_args(["-s", @tst_key_str, @tst_dat])
    assert_equal @tst_xored, @stdout_io.string
  end

  def test_string_arg_str_key_x_flag
    assert_equal 0, go_with_args(["-x", @tst_key_hex, @tst_dat])
    assert_equal @tst_xored, @stdout_io.string
  end

  def test_string_arg_xor_zeroes_out
    assert_equal 0, go_with_args(%w(-s foo foo))
    assert_equal "\x00"*3, @stdout_io.string
  end

  def test_string_arg_xor_zeroes_out_repeating
    assert_equal 0, go_with_args(%w(-s A AAAAAAAAAA))
    assert_equal "\x00"*10, @stdout_io.string
  end

  def test_string_arg_str_key_reverse_s_flag
    assert_equal 0, go_with_args(["-s", @tst_key_str, @tst_xored])
    assert_equal @tst_dat, @stdout_io.string
  end

  def test_string_arg_str_key_reverse_x_flag
    assert_equal 0, go_with_args(["-x", @tst_key_hex, @tst_xored])
    assert_equal @tst_dat, @stdout_io.string
  end

  def test_stdin
    @stdin_io.write(@tst_dat) ; @stdin_io.rewind
    assert_equal 0, go_with_args(["-s", @tst_key_str])
    assert_equal @tst_xored, @stdout_io.string
  end

  def test_file_input
    with_testfile do |fname, f|
      f.write(@tst_dat); f.close
      assert_equal 0, go_with_args(["-s", @tst_key_str, "-f", fname])
      assert_equal @tst_xored, @stdout_io.string
    end
  end

  def test_string_arg_no_key_error
    assert_equal 1, go_with_args(%w(foo))
    assert_match(/you must specify a key/i, @stderr_io.string)
  end

  def test_one_key_opt_error
    assert_equal 1, go_with_args(%w(-x foo -s foo foo))
    assert_match(/only one key option/i, @stderr_io.string)
  end

end
