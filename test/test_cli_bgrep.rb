require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/bgrep'

class TestCliBgrep < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Bgrep
    super()

    @rawdat = (0..255).map {|x| x.chr}.join
  end

  def test_need_search_arg
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
    assert_equal 1, go_with_args()
    assert_match(/need search argument/i, @stderr_io.string)
  end

  def test_search_arg_exclusive
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
    assert_equal 1, go_with_args(%w(-r ABCD -x 41424344))
    assert_match(/are mutually exclusive/i, @stderr_io.string)
  end

  def test_stdin_str_grep
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
    assert_equal 0, go_with_args(%w(-r ABCD))
    assert_equal %(00000041:00000045:b:"ABCD"\n), @stdout_io.string
  end

  def test_stdin_regex_grep
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
    assert_equal 0, go_with_args(%w(-r A..D))
    assert_equal %(00000041:00000045:b:"ABCD"\n), @stdout_io.string
  end

  def test_stdin_hex_grep
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
    assert_equal 0, go_with_args(%w(-x 41424344))
    assert_equal %(00000041:00000045:b:"ABCD"\n), @stdout_io.string
  end

  def test_alignment_arg
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
    assert_equal 0, go_with_args(%w(-a 2 -r BCDE))
    assert_equal %(00000042:00000046:b:"BCDE"\n), @stdout_io.string
  end

  def test_alignment_arg_not_aligned
    @stdin_io.write(@rawdat) ; @stdin_io.rewind
    assert_equal 0, go_with_args(%w(-a 2 -r ABCD))
    assert_equal "", @stdout_io.string
  end


  def test_stdin_str_grep_twohits
    @stdin_io.write(@rawdat*2) ; @stdin_io.rewind
    assert_equal 0, go_with_args(%w(-r ABCD))
    assert_equal %(00000041:00000045:b:"ABCD"\n00000141:00000145:b:"ABCD"\n), @stdout_io.string
  end

  def test_stdin_hex_grep_twohits
    @stdin_io.write(@rawdat*2) ; @stdin_io.rewind
    assert_equal 0, go_with_args(%w(-x 41424344))
    assert_equal( %(00000041:00000045:b:"ABCD"\n)+
                  %(00000141:00000145:b:"ABCD"\n), 
                  @stdout_io.string )
  end

  def test_file_arg
    with_testfile do |fname, f|
      f.write(@rawdat) ; f.close
      assert_equal 0, go_with_args(%w(-r ABCD) << fname)
      assert_equal %(00000041:00000045:b:"ABCD"\n), @stdout_io.string
    end
  end

  def test_multi_file_arg
    with_testfile do |fname1, f1|
      f1.write(@rawdat) ; f1.close

      with_testfile do |fname2, f2|
        f2.write(@rawdat) ; f2.close
        assert_equal 0, go_with_args(["-r", "ABCD", fname1, fname2])
        assert_equal( %(#{fname1}:00000041:00000045:b:"ABCD"\n)+ 
                      %(#{fname2}:00000041:00000045:b:"ABCD"\n), 
                      @stdout_io.string )
      end
    end
  end

  def test_multi_file_arg_include_filenames_long
    with_testfile do |fname1, f1|
      f1.write(@rawdat) ; f1.close

      with_testfile do |fname2, f2|
        f2.write(@rawdat) ; f2.close
        assert_equal 0, go_with_args(%w(--filename -r ABCD) + [fname1, fname2])
        assert_equal( %(#{fname1}:00000041:00000045:b:"ABCD"\n)+ 
                      %(#{fname2}:00000041:00000045:b:"ABCD"\n), 
                      @stdout_io.string )
      end
    end
  end

  def test_multi_file_arg_include_filenames_short
    with_testfile do |fname1, f1|
      f1.write(@rawdat) ; f1.close

      with_testfile do |fname2, f2|
        f2.write(@rawdat) ; f2.close
        assert_equal 0, go_with_args(%w(-n -r ABCD) + [fname1, fname2])
        assert_equal( %(#{fname1}:00000041:00000045:b:"ABCD"\n)+ 
                      %(#{fname2}:00000041:00000045:b:"ABCD"\n), 
                      @stdout_io.string )
      end
    end
  end


  def test_multi_file_arg_suppress_filenames_long
    with_testfile do |fname1, f1|
      f1.write(@rawdat) ; f1.close

      with_testfile do |fname2, f2|
        f2.write(@rawdat) ; f2.close
        assert_equal 0, go_with_args(%w(--no-filename -r ABCD)+[fname1, fname2])
        assert_equal( %(00000041:00000045:b:"ABCD"\n)+ 
                      %(00000041:00000045:b:"ABCD"\n), 
                      @stdout_io.string )
      end
    end
  end


end
