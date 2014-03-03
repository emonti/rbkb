require File.join(File.dirname(__FILE__), "test_cli_helper.rb")

require 'rbkb/cli/chars'

class TestCliChars < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Chars
    super()
  end

  def test_chars
    assert_equal 0, go_with_args(%w(1000 A))
    assert_equal "A"*1000, @stdout_io.string
  end

  def test_bad_arguments
    assert_equal 1, go_with_args(["asdf"])
    assert_match(/bad arguments/i, @stderr_io.string)
  end

end
