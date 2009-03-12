require File.dirname(__FILE__) + '/test_helper.rb'

class TestRbkb < Test::Unit::TestCase

  def setup
  end
  
  def test_truth
    assert true
  end

  # Must... have... green...
  def test_bones_stuff
    assert_equal Rbkb::VERSION, Rbkb.version
    assert_equal File.join(Rbkb::LIBPATH, "blah"), Rbkb.libpath("blah")
    assert_equal File.join(Rbkb::PATH, "blah"), Rbkb.path("blah")
  end

end
