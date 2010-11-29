require 'pp'
require 'stringio'
require 'test/unit'
$:.unshift  File.dirname(__FILE__) + '/../lib'


class StringIO_compat < StringIO
  def string(*args)
    s = super(*args)
    s.force_encoding("binary") if RUBY_VERSION >= "1.9"
    return s
  end
end
