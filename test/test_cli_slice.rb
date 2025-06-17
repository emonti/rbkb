require File.join(File.dirname(__FILE__), 'test_cli_helper.rb')
require 'rbkb/cli/slice'

class TestCliSlice < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Slice
    super()
    @rawdat = (0..255).map { |x| x.chr }.join
    @stdin_io.write(@rawdat)
    @stdin_io.rewind
  end

  def test_stdin
    assert_equal 0, go_with_args(%w[0])
    assert_equal @rawdat, @stdout_io.string
  end

  def test_start_from_end_negative_size
    assert_equal 0, go_with_args(%w[-- -10])
    assert_equal(@rawdat[-10..-1], @stdout_io.string)
  end

  def test_file_input_opt
    with_testfile do |fname, tf|
      tf.write @rawdat
      tf.close
      assert_equal 0, go_with_args(['-f', fname, '0'])
      assert_equal(@rawdat, @stdout_io.string)
    end
  end

  def test_bad_start
    assert_equal 1, go_with_args(%w[foo])
    assert_match(/invalid start length/i, @stderr_io.string)
  end

  def test_start_from_end_zero
    assert_equal 0, go_with_args(%w[-r 256])
    assert_equal('', @stdout_io.string)
  end

  def test_start_from_end_one
    assert_equal 0, go_with_args(%w[-r 255])
    assert_equal("\xff".force_to_binary, @stdout_io.string)
  end

  def test_start_from_overflow
    assert_equal 0, go_with_args(%w[-r 2000])
    assert_equal('', @stdout_io.string)
  end

  def test_range_start_end
    assert_equal 0, go_with_args(%w[-r 10:20])
    assert_equal(@rawdat[10..20], @stdout_io.string)
  end

  def test_range_start_and_end
    assert_equal 0, go_with_args(%w[-r 10:20])
    assert_equal(@rawdat[10..20], @stdout_io.string)
  end

  def test_range_start_and_end_with_negative_end
    assert_equal 0, go_with_args(%w[-r 0:-20])
    assert_equal(@rawdat[0..-20], @stdout_io.string)
  end

  def test_range_start_and_end_hex
    assert_equal 0, go_with_args(%w[-x 0a:14])
    assert_equal(@rawdat[10..20], @stdout_io.string)
  end
end
