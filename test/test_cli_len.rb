require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/len'

class TestCliLen < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Len
    super()

    @tst_in  = "helu world"
    @bigtst_in = "A"*65536
  end

  def test_string_arg
    assert_equal 0, go_with_args([@tst_in])
    assert_equal("\x00\x00\x00\x0a" + @tst_in, @stdout_io.string)
  end

  def test_big_string_arg
    assert_equal 0, go_with_args([@bigtst_in])
    assert_equal("\x00\x01\x00\x00" + @bigtst_in, @stdout_io.string)
  end

  def test_stdin
    @stdin_io.write(@tst_in) ; @stdin_io.rewind
    assert_equal 0, go_with_args()
    assert_equal("\x00\x00\x00\x0a" + @tst_in, @stdout_io.string)
  end

  def test_file_input_flag
    with_testfile do |fname, tf|
      tf.write @tst_in;  tf.close
      assert_equal 0, go_with_args(["-f", fname])
      assert_equal("\x00\x00\x00\x0a" + @tst_in, @stdout_io.string)
    end
  end

  def test_string_arg_swap
    assert_equal 0, go_with_args(["-x", @tst_in])
    assert_equal("\x0a\x00\x00\x00" + @tst_in, @stdout_io.string)
  end


  def test_big_string_arg_swap
    assert_equal 0, go_with_args(["-x", @bigtst_in])
    assert_equal("\x00\x00\x01\x00" + @bigtst_in, @stdout_io.string)
  end

  def test_big_string_arg_total
    assert_equal 0, go_with_args(["-t", @bigtst_in])
    assert_equal("\x00\x01\x00\x04" + @bigtst_in, @stdout_io.string)
  end

  def test_big_string_arg_static_len
    assert_equal 0, go_with_args(["-l3", @bigtst_in])
    assert_equal("\x00\x00\x00\x03" + @bigtst_in, @stdout_io.string)
  end

  def test_big_string_arg_static_len_negative
    assert_equal 0, go_with_args(["-l", "-3", @bigtst_in])
    assert_equal("\xff\xff\xff\xfd" + @bigtst_in, @stdout_io.string)
  end

  def test_big_string_arg_static_len_negative_short
    assert_equal 0, go_with_args(["-l", "-3", "-s2", @bigtst_in])
    assert_equal("\xff\xfd" + @bigtst_in, @stdout_io.string)
  end

  def test_big_string_arg_nudge
    assert_equal 0, go_with_args(["-n5", @bigtst_in])
    assert_equal("\x00\x01\x00\x05" + @bigtst_in, @stdout_io.string)
  end

  def test_big_string_arg_byte
    assert_equal 0, go_with_args(["-s1", @tst_in])
    assert_equal("\x0a" + @tst_in, @stdout_io.string)
  end

  def test_big_string_arg_byte_wrap
    assert_equal 0, go_with_args(["-s1", @bigtst_in])
    assert_equal("\x00" + @bigtst_in, @stdout_io.string)
  end


  def test_big_string_arg_short
    assert_equal 0, go_with_args(["-s2", @tst_in])
    assert_equal("\x00\x0a" + @tst_in, @stdout_io.string)
  end

  def test_big_string_arg_short_wrap
    assert_equal 0, go_with_args(["-s2", @bigtst_in])
    assert_equal("\x00\x00" + @bigtst_in, @stdout_io.string)
  end

end
