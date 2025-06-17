require File.join(File.dirname(__FILE__), 'test_cli_helper.rb')

class TestCliBlit < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Blit
    super()
  end
end
