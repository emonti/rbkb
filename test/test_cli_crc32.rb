require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/crc32'

class TestCliCrc32 < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Crc32
    super()
    @rawdat = "\306\363\375/l\375\204oK\215o\275\334\037\254\333\276\257\313\267\fr\231\333!\373v|\303W7p\263\307\034X\300~\2671R\252\026\246\263\231\276\314"
    @rawsz = @rawdat.size
    @crc_int = 0xa7641684
    @crc_out ="a7641684\n"
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
  end

  def test_stdin
    assert_equal 0, go_with_args()
    assert_equal(@crc_out, @stdout_io.string)
  end

  def test_file_input_arg
    with_testfile do |fname, tf| 
      tf.write @rawdat;  tf.close
      assert_equal 0, go_with_args([fname])
      assert_equal(@crc_out, @stdout_io.string)
    end
  end


  def test_file_input_flag
    with_testfile do |fname, tf| 
      tf.write @rawdat;  tf.close
      assert_equal 0, go_with_args(["-f", fname])
      assert_equal(@crc_out, @stdout_io.string)
    end
  end

  def test_start_from_end_zero
    assert_equal 0, go_with_args(%w(-r 48))
    assert_equal("00000000\n", @stdout_io.string)
  end

  def test_start_from_end_zero_hex
    assert_equal 0, go_with_args(%w(-x 00:30))
    assert_equal(@crc_out, @stdout_io.string)
  end

  def test_range_zero_start
    assert_equal 0, go_with_args(%w(-r 0:48))
    assert_equal(@crc_out, @stdout_io.string)
  end

  def test_range
    assert_equal 0, go_with_args(%w{-x 30})
    assert_equal("00000000\n", @stdout_io.string)
  end

  def test_range_sixteen_thru_end
    assert_equal 0, go_with_args(%w(-r 16))
    assert_equal "de84e464\n", @stdout_io.string
  end

  def test_range_sixteen_thru_end_hex
    assert_equal 0, go_with_args(%w(-x 10))
    assert_equal "de84e464\n", @stdout_io.string
  end

  def test_range_last_ten
    assert_equal 0, go_with_args(%w(-r 38:48))
    assert_equal "7d4bb02a\n", @stdout_io.string
  end

  def test_range_last_ten_hex
    assert_equal 0, go_with_args(%w(-x 26:30))
    assert_equal "7d4bb02a\n", @stdout_io.string
  end

  def test_invalid_range
    assert_equal 1, go_with_args(%w(-r 38:z48))
    assert_match(/invalid range/, @stderr_io.string)
  end

  def test_range_last_ten_hex_invalid
    assert_equal 1, go_with_args(%w(-x 26:z30))
    assert_match(/invalid range/, @stderr_io.string)
  end

  def test_range_last_ten_using_negative
    assert_equal 0, go_with_args(%w(-r 38:-1))
    assert_equal "7d4bb02a\n", @stdout_io.string
  end

  def test_range_last_ten_using_negative_hex
    assert_equal 0, go_with_args(%w(-x 26:-1))
    assert_equal "7d4bb02a\n", @stdout_io.string
  end

  def test_start_from_end_negative_size
    assert_equal 0, go_with_args(%w(-r -48))
    assert_equal(@crc_out, @stdout_io.string)
  end

  def test_start_from_end_negative_size_hex
    assert_equal 0, go_with_args(%w(-x -30))
    assert_equal(@crc_out, @stdout_io.string)
  end
end
