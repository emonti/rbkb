require File.join(File.dirname(__FILE__), "test_cli_helper.rb")

# FIXME Finish test cases for rstrings cli

class TestCliRstrings < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Rstrings
    super()

    @test_dat = "a\000bc\001def\002gehi\003jklmn\004string 1\005string 2\020\370\f string 3\314string4\221string 5\n\000string 6\r\n\000\000\000\000string 7\000\000w\000i\000d\000e\000s\000t\000r\000i\000n\000g\000\000\000last string\000"
  end

end
