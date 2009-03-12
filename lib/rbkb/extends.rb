# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
require "stringio"
require 'zlib'
require 'open3'
require 'sha1'

module Rbkb
  DEFAULT_BYTE_ORDER=:big
  HEXCHARS = [("0".."9").to_a, ("a".."f").to_a].flatten
end

# Generates a "universally unique identifier"
def uuid
  (SHA1::sha1(rand.to_s)).to_s
end

# Generates a random alphanumeric string of 'size' bytes (8 by default)
def random_string(size = 8)
  chars = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
  (1..size).collect{|a| chars[rand(chars.size)]}.join
end


# Simple syntactic sugar to pass any object to a block
def with(x)
  yield x if block_given?; x
end if not defined? with


#-----------------------------------------------------------------------------

# Mixins and class-specific items

class String
  # shortcut for hex sanity with regex
  def ishex? ; (self =~ /^[a-f0-9]+$/i)? true : false ; end 

  # Encode into percent-hexify url encoding format
  def urlenc(opts={})
    s=self
    plus = opts[:plus]
    unless (opts[:rx] ||= /[^A-Za-z0-9_\.~-]/).kind_of? Regexp
      raise "rx must be a regular expression for a character class"
    end
    hx = Rbkb::HEXCHARS

    s.gsub(opts[:rx]) do |c| 
      c=c[0]
      (plus and c==32)? '+' : "%" + (hx[(c >> 4)] + hx[(c & 0xf )])
    end
  end
  
  # Undo percent-hexified url encoding data
  def urldec(opts={})
    s=self
    s.gsub!('+', ' ') unless opts[:noplus]
    s.gsub(/%([A-Fa-f0-9]{2})/) {$1.hex.chr}
  end

  # Base64 encode
  def b64(len=nil)
    ret = [self].pack("m").gsub("\n", "")
    if len and Numeric === len 
      ret.scan(/.{1,#{len}}/).join("\n") + "\n"
    else
      ret
    end
  end

  # Base64 decode
  def d64;  self.unpack("m")[0];  end

  # right-align to 'a' alignment padded with 'p'
  def ralign(a, p=' ')
    s=self
    p ||= ' '
    l = s.length
    pad = l.pad(a)
    s.rjust(pad+l, p)
  end

  # left-align to 'a' alignment padded with 'p'
  def lalign(a, p=' ')
    s=self
    p ||= ' '
    l = s.length
    pad = l.pad(a)
    s.ljust(pad+l, p)
  end


  # Convert a string to ASCII hex string. Supports a few options for format:
  #
  #   :delim - delimter between each hex byte
  #   :prefix - prefix before each hex byte
  #   :suffix - suffix after each hex byte
  # 
  def hexify(opts={})
    s=self
    delim = opts[:delim]
    pre = (opts[:prefix] || "")
    suf = (opts[:suffix] || "")

    if (rx=opts[:rx]) and not rx.kind_of? Regexp
      raise "rx must be a regular expression for a character class"
    end

    hx=Rbkb::HEXCHARS

    out=Array.new

    s.each_byte do |c| 
      hc = if (rx and not rx.match c.chr)
             c.chr 
           else
             pre + (hx[(c >> 4)] + hx[(c & 0xf )]) + suf
           end
      out << (hc)
    end
    out.join(delim)
  end


  # Convert ASCII hex string to raw. 
  #
  # Parameters:
  #
  #   d = optional 'delimiter' between hex bytes (zero+ spaces by default)
  def unhexify(d=/\s*/)
    self.strip.gsub(/([A-Fa-f0-9]{1,2})#{d}?/) { $1.hex.chr }
  end

  # Converts a hex value to numeric.
  #
  # Parameters:
  #   
  #   order => :big or :little endian (default is :big)
  #
  def hex_to_num(order=:big)
    s=self
    raise "invalid hex value: '#{s.inspect}'" unless s.ishex?

    r = if order == :little
          s.scan(/.{2}/).reverse.join
        elsif order == :big
          s 
        else
          raise "Invalid byte order #{order.inspect}"
        end.hex
  end


  # A "generalized" lazy bytestring -> numeric converter.
  #
  # Parameters:
  #   
  #   order => :big or :little endian (default is :big)
  #
  # Bonus: should work seamlessly with really large strings.
  #
  #   >> ("\xFF"*10).dat_to_num
  #   => 1208925819614629174706175
  #   >> ("\xFF"*20).dat_to_num
  #   => 1461501637330902918203684832716283019655932542975
  #
  def dat_to_num(order=:big)
    s=self
    s.reverse! if order == :little
    r = 0
    s.each_byte {|c| r = ((r << 8) | c)}
    r
  end
  alias lazy_to_n dat_to_num
  alias lazy_to_num dat_to_num
  alias dat_to_n dat_to_num


  #### Crypto'ey stuff

  # calculates entropy in string
  #
  # TQBF's description:
  # "I also added a chi-squared test to quickly figure out entropy of a
  # string, in "bits of randomness per byte". This is useful, so..."
  def entropy
    e = 0
    0.upto(255) do |i|
      x = count(i.chr)/size.to_f
      if x > 0
        e += - x * x.log2
      end
    end
    e
  end

  # xor against a key. key will be repeated or truncated to self.size.
  def xor(k)
    s=self
    out=StringIO.new ; i=0;
    s.each_byte do |x| 
      out.write((x ^ (k[i] || k[i=0]) ).chr)
      i+=1
    end
    out.string
  end

  # convert bytes to number then xor against another byte-string or number
  def ^(x)
    x = x.dat_to_num unless x.is_a? Numeric
    (self.dat_to_num ^ x)#.to_bytes
  end

  # String randomizer
  def randomize ; self.split('').randomize.to_s ; end

  # In-place string randomizer
  def randomize! ; self.replace(randomize) end


  # Returns or prints a hexdump in the style of 'hexdump -C'
  #
  # :len => optionally specify a length other than 16 for a wider or thinner 
  # dump. If length is an odd number, it will be rounded up.
  #
  # :out => optionally specify an alternate IO object for output. By default,
  # hexdump will output to STDOUT.  Pass a StringIO object and it will return 
  # it as a string.
  #
  # Example:
  #
  # Here's the default behavior done explicitely:
  #
  #   >> xxd = dat.hexdump(:len => 16, :out => StringIO.new)
  #   => <a string containing hexdump>
  #
  # Here's how to change it to STDERR
  #
  #   >> xxd = dat.hexdump(:len => 16, :out => STDERR)
  #   <prints hexdump on STDERR>
  #   -> nil # return value is nil!
  #
  def hexdump(opt={})
    s=self
    out = opt[:out] || StringIO.new
    len = (opt[:len] and opt[:len] > 0)? opt[:len] + (opt[:len] % 2) : 16

    off = opt[:start_addr] || 0
    offlen = opt[:start_len] || 8

    hlen=len/2

    s.scan(/(?:.|\n){1,#{len}}/) do |m|
      out.write(off.to_s(16).rjust(offlen, "0") + '  ')

      i=0
      m.each_byte do |c|
        out.write c.to_s(16).rjust(2,"0") + " "
        out.write(' ') if (i+=1) == hlen
      end

      out.write("   " * (len-i) ) # pad
      out.write(" ") if i < hlen

      out.write(" |" + m.tr("\0-\37\177-\377", '.') + "|\n")
      off += m.length
    end

    out.write(off.to_s(16).rjust(offlen,'0') + "\n")

    if out.class == StringIO
      out.string
    end
  end


  # Converts a hexdump back to binary - takes the same options as hexdump().
  # Fairly flexible. Should work both with 'xxd' and 'hexdump -C' style dumps.
  def dehexdump(opt={})
    s=self
    out = opt[:out] || StringIO.new
    len = (opt[:len] and opt[:len] > 0)? opt[:len] : 16

    hcrx = /[A-Fa-f0-9]/
    dumprx = /^(#{hcrx}+):?\s*((?:#{hcrx}{2}\s*){0,#{len}})/
    off = opt[:start_addr] || 0

    i=1
    # iterate each line of hexdump
    s.split(/\r?\n/).each do |hl|
      # match and check offset
      if m = dumprx.match(hl) and $1.hex == off
        i+=1
        # take the data chunk and unhexify it
        raw = $2.unhexify
        off += out.write(raw)
      else
        raise "Hexdump parse error on line #{i} #{s}"
      end
    end

    if out.class == StringIO
      out.string
    end
  end
  alias dedump dehexdump
  alias undump dehexdump
  alias unhexdump dehexdump


  # Binary grep
  # 
  # Parameters:
  #
  #   find  : A Regexp or string to search for in self
  #   align : nil | numeric alignment (matches only made if aligned)
  def bgrep(find, align=nil)
    if align and (not align.is_a?(Integer) or align < 0)
      raise "alignment must be a integer >= 0"
    end

    dat=self
    if find.kind_of? Regexp
      search = lambda do |find, buf| 
        if m = find.match(buf)
          mtch = m[0]
          off,endoff = m.offset(0)
          return off, endoff, mtch
        end
      end
    else
      search = lambda do |find, buf|
        if off = buf.index(find)
          return off, off+find.size, find
        end
      end
    end

    ret=[]
    pos = 0
    while (res = search.call(find, dat[pos..-1]))
      off, endoff, match = res
      if align and ( pad = (pos+off).pad(align) ) != 0
        pos += pad
      else
        hit = [pos+off, pos+endoff, match]
        if not block_given? or yield([pos+off, pos+endoff, match])
          ret << hit
        end
        pos += endoff
      end
    end
    return ret
  end

  # A 'strings' method a-la unix strings utility. Finds printable strings in
  # a binary blob.
  # Supports ASCII and little endian unicode (though only for ASCII printable 
  # character.)
  #
  # === Parameters and options:
  #
  #  * Use the :minimum parameter to specify minimum number of characters
  #    to match. (default = 6)
  #
  #  * Use the :encoding parameter as one of :ascii, :unicode, or :both
  #    (default = :ascii)
  #
  #  * The 'strings' method uses Regexp under the hood. Therefore
  #    you can pass a character class for "valid characters" with :valid
  #    (default = /[\r\n [:print:]]/)
  #
  #  * Supports an optional block, which will be passed |offset, type, string|
  #    for each match.
  #    The block's boolean return value also determines whether the match 
  #    passes or fails (true or false/nil) and gets returned by the function.
  #
  # === Return Value:
  #
  # Returns an array consisting of matches with the following elements:
  #
  #   [[start_offset, end_offset, string_type, string], ...]
  #
  #  * string_type will be one of :ascii or :unicode
  #  * end_offset will include the terminating null character
  #  * end_offset will include all null bytes in unicode strings (including
  #  * both terminating nulls)
  # 
  #   If strings are null terminated, the trailing null *IS* included
  #   in the end_offset. Unicode matches will also include null bytes.
  #
  # Todos?
  #    - better unicode support (i.e. not using half-assed unicode)
  #    - support other encodings such as all those the binutils strings does?
  #    - not sure if we want the trailing null in null terminated strings
  #    - not sure if we want wide characters to include their null bytes
  def strings(opts={})
    opts[:encoding] ||= :both
    prx = (opts[:valid] || /[\r\n [:print:]]/)
    min = (opts[:minimum] || 6)
    align = opts[:align]

    raise "Minimum must be numeric and > 0" unless min.kind_of? Numeric and min > 0

    arx = /(#{prx}{#{min}}?#{prx}*\x00?)/
    urx = /((?:#{prx}\x00){#{min}}(?:#{prx}\x00)*(?:\x00\x00)?)/

    rx = case (opts[:encoding] || :both).to_sym
         when :ascii   : arx
         when :unicode : urx
         when :both    : Regexp.union( arx, urx )
         else 
           raise "Encoding must be :unicode, :ascii, or :both"
         end

    off=0
    ret = []

    while mtch = rx.match(self[off..-1])
      # calculate relative offsets
      rel_off = mtch.offset(0)
      startoff = off + rel_off[0]
      endoff   = off + rel_off[1]
      off += rel_off[1]

      if align and (pad=startoff.pad(align)) != 0
        off = startoff + pad
        next
      end

      stype = if mtch[1]
                :ascii
              elsif mtch[2]
                :unicode
              end


      mret = [startoff, endoff, stype, mtch[0] ]

      # yield to a block for additional criteria
      next if block_given? and not yield( *mret )

      ret << mret
    end

    return ret
  end

  # Does string "start with" dat?
  # No clue whether/when this is faster than a regex, but it is easier to type.
  def starts_with?(dat)
    self[0,dat.size] == dat
  end

  # Returns a single null-terminated ascii string from beginning of self.
  # This will return the entire string if no null is encountered.
  #
  # Parameters:
  #
  #   off = specify an optional beggining offset
  #
  def cstring(off=0)
    self[ off, self.index("\x00") || self.size ]
  end

  # returns CRC32 checksum for the string object
  def crc32
    ## pure ruby version. slower, but here for reference (found on some forum)
    #  r = 0xFFFFFFFF
    #  self.each_byte do |b|
    #    r ^= b
    #    8.times do
    #      r = (r>>1) ^ (0xEDB88320 * (r & 1))
    #    end
    #  end
    #  r ^ 0xFFFFFFFF
    ## or... we can just use:
    Zlib.crc32 self
  end

  # This attempts to identify a blob of data using 'file(1)' via popen3
  # (using popen3 because IO.popen blows)
  # Tried doing this with a fmagic ruby extention to libmagic, but it was
  # a whole lot slower.
  def pipe_magick(arg="")
    ret=""
    Open3.popen3("file #{arg} -") do |w,r,e|
      w.write self; w.close
      ret = r.read ; r.close
      ret.sub!(/^\/dev\/stdin: /, "")
    end
    ret
  end

  # convert a string to its idiomatic ruby class name
  def class_name
    r = ""
    up = true
    each_byte do |c|
      if c == 95
        if up
          r << "::"
        else
          up = true
        end
      else
        m = up ? :upcase : :to_s
        r << (c.chr.send(m))
        up = false
      end
    end
    r
  end

  

  # Returns a reference to actual constant for a given name in namespace
  # can be used to lookup classes from enums and such
  def const_lookup(ns=Object)
    if c=ns.constants.select {|n| n == self.class_name } and not c.empty?
      ns.const_get(c.first)
    end
  end

end # class String

class Symbol
  # looks up this symbol as a constant defined in 'ns' (Object by default)
  def const_lookup(ns=Object)
    self.to_s.const_lookup(ns)
  end
end

class Array
  # randomizes the order of contents in the Array (self)
  def randomize  ; self.sort_by { rand } ; end

  # Returns a randomly chosen element from self.
  # Drew *is* sparta.
  def rand_elem;  self[rand(self.length)] ; end
end

class Float
  def log2; Math.log(self)/Math.log(2); end
end


class Numeric

  # calculate padding based on alignment(a)
  def pad(a)
    raise "bad alignment #{a.inspect}" unless a.kind_of? Numeric and a > 0
    return self < 1 ? a + self : (a-1) - (self-1) % a
  end

  # tells you whether a number is within printable range
  def printable?; self >= 0x20 and self <= 0x7e; end
 
  # just to go with the flow
  def randomize ; rand(self) ; end

  # shortcut for packing a single number... wtf...
  def pack(arg) ; [self].pack(arg) ; end

  def clear_bits(c) ; (self ^ (self & c)) ; end

  # Returns an array of chars per 8-bit break-up.
  # Accepts a block for some transformation on each byte.
  # (used by to_bytes and to_hex under the hood)
  #
  # args: 
  #   order: byte order - :big or :little
  #                       (only :big has meaning)
  #   siz:  pack to this size. larger numbers will wrap
  def to_chars(order=nil, siz=nil)
    order ||= Rbkb::DEFAULT_BYTE_ORDER
    n=self
    siz ||= self.size
    ret=[]
    siz.times do 
      c = (n % 256)
      if block_given? then (c = yield(c)) end
      ret << c
      n=(n >> 8)
    end
    return ((order == :big)? ret.reverse  : ret)
  end

  # "packs" a number into bytes using bit-twiddling instead of pack()
  #
  # Uses to_chars under the hood. See also: to_hex
  #
  # args: 
  #   siz:  pack to this size. larger numbers will wrap
  #   order: byte order - :big or :little
  #                       (only :big has meaning)
  def to_bytes(order=nil, siz=nil)
    to_chars(order,siz) {|c| c.chr }.join
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
  def to_hex(o=nil, s=nil)
    to_chars(o,s) {|c| 
      Rbkb::HEXCHARS[c.clear_bits(0xf) >> 4]+Rbkb::HEXCHARS[c.clear_bits(0xf0)]
    }.join
  end

  # TODO Fix Numeric.to_guid for new to_bytes/char etc.
#  def to_guid(order=Rbkb::DEFAULT_BYTE_ORDER)
#    raw = self.to_bytes(order, 16)
#    a,b,c,d,*e = raw.unpack("VvvnC6").map{|x| x.to_hex}
#    e = e.join
#    [a,b,c,d,e].join("-").upcase
#  end

end # class Numeric


# some extra features for zlib... more to come?
module Zlib
  OSMAP = {
    OS_MSDOS    => :msdos,
    OS_AMIGA    => :amiga,
    OS_VMS      => :vms,
    OS_UNIX     => :unix,
    OS_ATARI    => :atari,
    OS_OS2      => :os2,
    OS_TOPS20   => :tops20,
    OS_WIN32    => :win32,
    OS_VMCMS    => :vmcms,
    OS_ZSYSTEM  => :zsystem,
    OS_CPM      => :cpm,
    OS_RISCOS   => :riscos,
    OS_UNKNOWN  => :unknown
  }

  # Helpers for Zlib::GzipFile... more to come?
  class GzipFile

    ## extra info dump for gzipped files
    def get_xtra_info
      info = {
        :file_crc     => crc.to_hex,
        :file_comment => comment,
        :file_name    => orig_name,
        :level        => level,
        :mtime        => mtime,
        :os           =>  (Zlib::OSMAP[os_code] || os_code)
      }
    end
  end
end

class Object
  ## This is from Topher Cyll's Stupd IRB tricks
  def mymethods
    (self.methods - self.class.superclass.methods).sort
  end
end

module Enumerable
  def each_recursive(&block)
    self.each do |n|
      block.call(n)
      n.each_recursive(&block) if n.kind_of? Array or n.kind_of? Hash
    end
  end
end

