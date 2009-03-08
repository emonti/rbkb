require File.join(File.dirname(__FILE__), "test_helper.rb")
require 'stdio'
require 'rbkb/cli/hexify'

class TestHexifyCli < Test::Unit::TestCase
  def setup
    @stdout_io = StringIO.new
    @stderr_io = StringIO.new
    @stdin_io  = StringIO.new
    @hexify = Rbkb::Cli::Hexify
  end
end
