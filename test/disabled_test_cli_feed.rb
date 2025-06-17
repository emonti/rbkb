require File.join(File.dirname(__FILE__), 'test_cli_helper.rb')

class TestCliFeed < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Feed
    super()
  end
end
