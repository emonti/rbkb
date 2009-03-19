require File.join(File.dirname(__FILE__), "test_cli_helper.rb")

class TestCliRstrings < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Rstrings
    super()
  end

end
