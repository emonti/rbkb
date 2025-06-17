require 'rbkb/extends/common'

class Numeric
  # calculate padding based on alignment(a)
  def pad(a)
    raise "bad alignment #{a.inspect}" unless a.is_a? Numeric and a > 0

    self < 1 ? a + self : (a - 1) - (self - 1) % a
  end

  # tells you whether a number is within printable range
  def printable?
    self >= 0x20 and self <= 0x7e
  end

  # shortcut for packing a single number... wtf...
  def pack(arg)
    [self].pack(arg)
  end

  def clear_bits(c)
    (self ^ (self & c))
  end

  # Returns an array of chars per 8-bit break-up.
  # Accepts a block for some transformation on each byte.
  # (used by to_bytes and to_hex under the hood)
  #
  # args:
  #   order: byte order - :big or :little
  #                       (only :big has meaning)
  #   siz:  pack to this size. larger numbers will wrap
  def to_chars(order = nil, siz = nil)
    order ||= Rbkb::DEFAULT_BYTE_ORDER
    n = self
    siz ||= size
    ret = []
    siz.times do
      c = (n % 256)
      if block_given? then (c = yield(c)) end
      ret << c
      n = (n >> 8)
    end
    (order == :big ? ret.reverse : ret)
  end

  # "packs" a number into bytes using bit-twiddling instead of pack()
  #
  # Uses to_chars under the hood. See also: to_hex
  #
  # args:
  #   siz:  pack to this size. larger numbers will wrap
  #   order: byte order - :big or :little
  #                       (only :big has meaning)
  def to_bytes(order = nil, siz = nil)
    to_chars(order, siz) { |c| c.chr }.join
  end

  # Converts a number to hex string with width and endian options.
  # "packs" a number into bytes using bit-twiddling instead of pack()
  #
  # Uses to_chars under the hood. See also: to_bytes
  #
  # args:
  #   siz:  pack to this size. larger numbers will wrap
  #   order: byte order - :big or :little
  #                       (only :big has meaning)
  #
  def to_hex(o = nil, s = nil)
    to_chars(o, s) do |c|
      Rbkb::HEXCHARS[c.clear_bits(0xf) >> 4] + Rbkb::HEXCHARS[c.clear_bits(0xf0)]
    end.join
  end

  # TODO: Fix Numeric.to_guid for new to_bytes/char etc.
  #  def to_guid(order=Rbkb::DEFAULT_BYTE_ORDER)
  #    raw = self.to_bytes(order, 16)
  #    a,b,c,d,*e = raw.unpack("VvvnC6").map{|x| x.to_hex}
  #    e = e.join
  #    [a,b,c,d,e].join("-").upcase
  #  end
end # class Numeric
