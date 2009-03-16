require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
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

  def test_allchars
    allchars_dec = (0..255).map {|c| c.chr}.join
    allchars_enc =  "%00%01%02%03%04%05%06%07%08%09%0a%0b%0c%0d%0e%0f%10%11%12%13%14%15%16%17%18%19%1a%1b%1c%1d%1e%1f%20%21%22%23%24%25%26%27%28%29%2a%2b%2c-.%2f0123456789%3a%3b%3c%3d%3e%3f%40ABCDEFGHIJKLMNOPQRSTUVWXYZ%5b%5c%5d%5e_%60abcdefghijklmnopqrstuvwxyz%7b%7c%7d~%7f%80%81%82%83%84%85%86%87%88%89%8a%8b%8c%8d%8e%8f%90%91%92%93%94%95%96%97%98%99%9a%9b%9c%9d%9e%9f%a0%a1%a2%a3%a4%a5%a6%a7%a8%a9%aa%ab%ac%ad%ae%af%b0%b1%b2%b3%b4%b5%b6%b7%b8%b9%ba%bb%bc%bd%be%bf%c0%c1%c2%c3%c4%c5%c6%c7%c8%c9%ca%cb%cc%cd%ce%cf%d0%d1%d2%d3%d4%d5%d6%d7%d8%d9%da%db%dc%dd%de%df%e0%e1%e2%e3%e4%e5%e6%e7%e8%e9%ea%eb%ec%ed%ee%ef%f0%f1%f2%f3%f4%f5%f6%f7%f8%f9%fa%fb%fc%fd%fe%ff"
    assert_equal 0, run_with_args([allchars_enc])
    assert_equal allchars_dec, @stdout_io.string
  end


end
