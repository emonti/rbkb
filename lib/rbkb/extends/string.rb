require 'rbkb/extends/common'
require 'rbkb/extends/numeric'
require 'cgi'

module Rbkb
  module Extends
    module String
      # This is so disgusting... but str.encode('BINARY') 
      # fails hard whenever certain utf-8 characters 
      # present. Try "\xca\xfe\xba\xbe".encode('BINARY')
      # for kicks.
      def force_to_binary
        self.dup.force_encoding('binary')
      end

      def ishex?
        (self =~ /\A([a-f0-9]{2}|\n)+\Z/i) == 0
      end

      # Encode to precent-hexify url encoded string
      # @param [Hash] opts Optional parameters
      # @option opts [optional, Boolean] :plus
      #     Treat + as a literal '+', instead of a space
      def urlenc(opts={})
        s=self
        plus = opts[:plus]
        unless (opts[:rx] ||= /[^A-Za-z0-9_\.~-]/).kind_of? Regexp
          raise "rx must be a regular expression for a character class"
        end
        hx = Rbkb::HEXCHARS

        s.force_to_binary.gsub(opts[:rx]) do |c|
          c=c.ord
          (plus and c==32)? '+' : "%" + (hx[(c >> 4)] + hx[(c & 0xf )])
        end
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
      def d64
        self.unpack("m").first
      end

      # right-align to 'a' alignment padded with 'p'
      def ralign(a, p=' ')
        p ||= ' '
        l = self.bytesize
        pad = l.pad(a)
        self.rjust(pad+l, p)
      end

      # left-align to 'a' alignment padded with 'p'
      def lalign(a, p=' ')
        p ||= ' '
        l = self.bytesize
        pad = l.pad(a)
        self.ljust(pad+l, p)
      end

      # Undo percent-hexified url encoded string
      # @param [Hash] opts Optional parameters
      # @option opts [optional, Boolean] :noplus
      #     Treat + as a literal '+', instead of a space
      def urldec(opts=nil)
        if opts.nil? or opts.empty?
          CGI.unescape(self)
        else
          s=self
          s.gsub!('+', ' ') unless opts[:noplus]
          s.gsub(/%([A-Fa-f0-9]{2})/) {$1.hex.chr}
        end
      end

      # Convert a string to ASCII hex string. Supports a few options for
      # format:
      #
      # @param [Hash] opts
      #
      # @option opts [String] :delim
      #   delimter between each hex byte
      #
      # @option opts [String] :prefix
      #   prefix before eaech hex byte
      #
      # @option opts [String] :suffix
      #   suffix after each hex byte
      #
      def hexify(opts={})
        delim = opts[:delim]
        pre = (opts[:prefix] || "")
        suf = (opts[:suffix] || "")

        if (rx=opts[:rx]) and not rx.kind_of? Regexp
          raise "rx must be a regular expression for a character class"
        end

        hx=Rbkb::HEXCHARS

        out=Array.new

        self.each_byte do |c| 
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
      #   @param [String] d optional 'delimiter' between hex bytes
      #                   (zero+ spaces by default)
      def unhexify(d=/\s*/)
        self.force_to_binary.strip.gsub(/([A-Fa-f0-9]{1,2})#{d}?/) { $1.hex.chr }
      end

      # Converts a hex value to numeric.
      #
      # Parameters:
      #   
      #   order => :big or :little endian (default is :big)
      #
      def hex_to_num(order=Rbkb::DEFAULT_BYTE_ORDER)
        self.unhexify.dat_to_num(order)
      end


      # A "generalized" lazy bytestring -> numeric converter.
      #
      # @param [Symbol] order :big or :little endian (default is :big)
      #
      # Bonus: should work seamlessly with really large strings.
      #
      #   >> ("\xFF"*10).dat_to_num
      #   => 1208925819614629174706175
      #   >> ("\xFF"*20).dat_to_num
      #   => 1461501637330902918203684832716283019655932542975
      #
      def dat_to_num(order=Rbkb::DEFAULT_BYTE_ORDER)
        b = self.bytes
        b = b.to_a.reverse if order == :little
        r = 0
        b.each {|c| r = ((r << 8) | c)}
        r
      end


      #### Crypto'ey stuff

      # calculates entropy in string
      #
      # TQBF's description:
      # "I also added a chi-squared test to quickly figure out entropy of a
      # string, in "bits of randomness per byte". This is useful, so..."
      def entropy
        e = 0
        sz = self.bytesize.to_f
        b = self.bytes
        0.upto(255) do |i|
          x = b.count(i)/sz
          if x > 0
            e += - x * (Math.log(x)/Math.log(2))
          end
        end
        e
      end


      # Produces a character frequency distribution histogram in descending
      # order. Example:
      #
      #   pp some_english_text.char_frequency()
      #
      #   [[" ", 690],
      #    ["e", 354],
      #    ["t", 242],
      #    ["o", 233],
      #    ["i", 218],
      #    ...
      #   ]
      #
      def char_frequency
        hits = {}
        self.each_byte {|c| hits[c.chr] ||= 0; hits[c.chr] += 1 }
        hits.to_a.sort {|a,b| b[1] <=> a[1] }
      end

      # xor against a key. key will be repeated or truncated to self.size.
      def xor(k)
        i=0
        self.bytes.map do |b|
          x = k.getbyte(i) || k.getbyte(i=0)
          i+=1 
          (b ^ x).chr
        end.join
      end


      # (en|de)ciphers using a substition cipher en/decoder ring in the form of a 
      # hash with orig => substitute mappings
      def substitution(keymap)
        split('').map {|c| (sub=keymap[c]) ? sub : c }.join
      end


      # (en|de)crypts using a substition xor en/decoder ring in the form of 
      # a hash with orig => substitute mappings. Used in conjunction with 
      # char_frequency, this sometimes provides a shorter way to derive a single 
      # character xor key used in conjunction with char_frequency.
      def substitution_xor(keymap)
        split('').map {|c| (sub=keymap[c]) ? sub.xor(c) : c }.join
      end


      # convert bytes to number then xor against another byte-string or number
      def ^(x)
        x = x.dat_to_num unless x.is_a? Numeric
        (self.dat_to_num ^ x)#.to_bytes
      end


      # Byte rotation as found in lame ciphers.
      def rotate_bytes(k=0)
        k = (256 + k) if k < 0
        self.bytes.map {|c| ((c + k) & 0xff).chr }.join
      end


      # String randomizer
      def randomize
        self.split('').randomize.join
      end


      # In-place string randomizer
      def randomize!
        self.replace(randomize)
      end

      # Does string "start with" dat?
      # No clue whether/when this is faster than a regex, but it is easier to type.
      def starts_with?(dat)
        self.index(dat) == 0
      end

      # Returns a single null-terminated ascii string from beginning of self.
      # This will return the entire string if no null is encountered.
      #
      # Parameters:
      #
      #   off = specify an optional beggining offset
      #
      def cstring(off=0)
        self[ off, (self.index("\x00") || self.size) ]
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

      # @return [Digest::MD5] the MD5 digest/checksum for this string.
      def md5
        d=Digest::MD5.new()
        d.update(self)
        d
      end
      alias md5sum md5

      # @return [Digest::SHA1] the SHA1 digest for this string.
      def sha1
        d=Digest::SHA1.new()
        d.update(self)
        d
      end

      # @return [Digest::SHA2] the SHA2 digest for this string.
      def sha2
        d=Digest::SHA2.new()
        d.update(self)
        d
      end
      alias sha256 sha2

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

      # Converts a '_' delimited string to CamelCase like 'foo_class' into 
      # 'FooClass'.
      # See also: camelize_meth, decamelize
      def camelize
        self.gsub(/(^|_)([a-z])/) { $2.upcase }
      end

      # Converts a '_' delimited string to method style camelCase like 'foo_method'
      # into 'fooMethod'.
      # See also: camelize, decamelize
      def camelize_meth
        self.gsub(/_([a-z])/) { $1.upcase }
      end


      # Converts a CamelCase or camelCase string into '_' delimited form like
      # 'FooBar' or 'fooBar' into 'foo_bar'. 
      #
      # Note: This method only handles camel humps. Strings with consecutive 
      # uppercase chars like 'FooBAR' will be converted to 'foo_bar'
      #
      # See also: camelize, camelize_meth
      def decamelize
        self.gsub(/(^|[a-z])([A-Z])/) do 
          ($1.empty?)? $2 : "#{$1}_#{$2}"
        end.downcase
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

      # Return a self encapsulated in a StringIO object. This is handy.
      def to_stringio
        StringIO.new(self)
      end

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

        s.bytes.each_slice(len) do |m|
          out.write(off.to_s(16).rjust(offlen, "0") + '  ')

          i=0
          m.each do |c|
            out.write "%0.2x " % c
            out.write(' ') if (i+=1) == hlen
          end

          out.write("   " * (len-i) ) # pad
          out.write(" ") if i < hlen

          out.write(" |")
          m.each do |c|
            if c > 0x19 and c < 0x7f
              out.write(c.chr)
            else
              out.write('.')
            end
          end
          out.write("|\n")
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
          if dumprx.match(hl) and $1.hex == off
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
          search = lambda do |mf, buf| 
            if m = mf.match(buf)
              mtch = m[0]
              off,endoff = m.offset(0)
              return off, endoff, mtch
            end
          end
        else
          search = lambda do |s, buf|
            if off = buf.index(s)
              return off, off+s.size, s
            end
          end
        end

        ret=[]
        pos = 0
        while (res = search.call(find, dat[pos..-1].force_to_binary))
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
      def strings(opts={})
        opts[:encoding] ||= :both
        min = (opts[:minimum] || 6)

        raise "Minimum must be numeric and > 0" unless min.kind_of? Numeric and min > 0

        acc = /[\s[:print:]]/
        ucc = /(?:#{acc}\x00)/

        arx = /(#{acc}{#{min}}#{acc}*\x00?)/
        urx = /(#{ucc}{#{min}}#{ucc}*(?:\x00\x00)?)/

        rx = case (opts[:encoding] || :both).to_sym
             when :ascii   
               mtype_blk = lambda {|x| :ascii }
               arx
             when :unicode 
               mtype_blk = lambda {|x| :unicode }
               urx
             when :both    
               mtype_blk = lambda {|x| (x[2].nil?)? :ascii : :unicode }

               Regexp.union( arx, urx )
             else 
               raise "Encoding must be :unicode, :ascii, or :both"
             end

        ret = []

        # wow ruby 1.9 string encoding is a total cluster
        self.force_to_binary.scan(rx) do 
          mtch = $~

          stype = mtype_blk.call(mtch)

          startoff, endoff = mtch.offset(0)
          mret = [startoff, endoff, stype, mtch[0] ]

          # yield to a block for additional criteria
          next if block_given? and not yield( *mret )

          ret << mret
        end

        return ret
      end


    end
  end
end

class RbkbString < String
  include Rbkb::Extends::String
end

def RbkbString(x)
  RbkbString.new(x)
end

