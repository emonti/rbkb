require_relative 'spec_helper'
require 'rbkb/extends/string'

# note by definition extends are really meant to be used as mixins or 
# monkey-patches on base classes (like String) But here we use
# RbkbString to avoid performing the mixin for our tests
describe Rbkb::Extends::String do
  it "should hexify" do
    RbkbString("foo").hexify.should == "666f6f"
    RbkbString("foo").hexify(:delim => ':').should == "66:6f:6f"
  end

  it "should unhexify" do
    RbkbString("666f6f").unhexify.should == "foo"
    RbkbString("66:6f:6f").unhexify(':').should == "foo"
  end


  it "should url-encode a string" do
    RbkbString("foo").urlenc().should == "foo"
    RbkbString("foo\n").urlenc().should == "foo%0a"
    RbkbString("foo ").urlenc().should == "foo%20"
    RbkbString("foo ").urlenc(plus:true).should == "foo+"
    RbkbString("foo\xff\n").urlenc().should == "foo%ff%0a"
    RbkbString("foo").urlenc(rx:/./).should == "%66%6f%6f"
  end

  it "should url-decode a string" do
    RbkbString("%66%6f%6f").urldec.should == "foo"
    RbkbString("foo%0a").urldec.should == "foo\n"
    RbkbString("foo%20").urldec.should == "foo "
    RbkbString("foo+").urldec.should == "foo "
    RbkbString("foo%ff\n").urldec.should == "foo\xFF\n".force_encoding('ascii')
  end


  it "should base-64 encode a string" do
    RbkbString("fooby").b64.should == "Zm9vYnk="
    RbkbString("\xca\xfe\xba\xbe").b64.should == "yv66vg=="
    RbkbString("foo\xFF\n".force_encoding('ascii')).b64.should == "Zm9v/wo="
  end

  it "should base-64 decode a string" do
    RbkbString("Zm9vYnk=").d64.should == "fooby"
    RbkbString("yv66vg==").d64.should == "\xca\xfe\xba\xbe"
    RbkbString("yv66vg==").d64.bytes.to_a.should == [0xca,0xfe,0xba,0xbe]
    RbkbString("Zm9v/wo=").d64.bytes.to_a.should == [0x66, 0x6f, 0x6f, 0xff, 0x0a]
   end

  it "should identify whether a string is all hex" do
    RbkbString("foo").ishex?.should be_false
    RbkbString("fa").ishex?.should be_true
    RbkbString("faf").ishex?.should be_false
    RbkbString("fa\nfa").ishex?.should be_true
    RbkbString("fa\nfa\n").ishex?.should be_true
    RbkbString(RbkbString((0..255).map{|x| x.chr}.join).hexify).ishex?.should be_true
  end

  it "should convert a raw string to number" do
    RbkbString("\xFF"*10).dat_to_num.should == 1208925819614629174706175
    RbkbString("\xFF"*20).dat_to_num.should == 1461501637330902918203684832716283019655932542975
  end

  it "should convert a hex string to number" do
    RbkbString("FF"*10).hex_to_num.should == 1208925819614629174706175
    RbkbString("FF"*20).hex_to_num.should == 1461501637330902918203684832716283019655932542975
  end

  it "should calculate the entropy of a string" do
    RbkbString("\xFF"*10).entropy.should == 0.0
    RbkbString("ABCD").entropy.should == 2.0
    RbkbString("ABCD"*10).entropy.should == 2.0
    RbkbString((0..255).to_a.map{|x| x.chr}.join).entropy.should == 8.0
  end


  it "should right/left align a string" do
    RbkbString("foo").ralign(4).should == " foo"
    RbkbString("foo").lalign(4).should == "foo "
    RbkbString("fooby").ralign(4).should == "   fooby"
    RbkbString("fooby").lalign(4).should == "fooby   "

    RbkbString("foo").ralign(4,"\x00").should == "\x00foo"
    RbkbString("foo").lalign(4,"\x00").should == "foo\x00"
    RbkbString("fooby").ralign(4,"\x00").should == "\x00\x00\x00fooby"
    RbkbString("fooby").lalign(4,"\x00").should == "fooby\x00\x00\x00"
  end

  context 'hexdump' do
    before :all do
      @tst_string = RbkbString("this is a \x00\n\n\ntest\x01\x02\xff\x00")
      @tst_dump = RbkbString.new <<_EOF_
00000000  74 68 69 73 20 69 73 20  61 20 00 0a 0a 0a 74 65  |this is a ....te|
00000010  73 74 01 02 ff 00                                 |st....|
00000016
_EOF_
    end

    it "should create a hexdump from a string" do
      @tst_string.hexdump.should == @tst_dump
    end

    it "should dedump a hexdump back to a string" do
      @tst_dump.dedump.bytes.to_a.should == @tst_string.bytes.to_a
    end
  end

end
