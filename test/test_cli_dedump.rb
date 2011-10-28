require File.join(File.dirname(__FILE__), "test_cli_helper.rb")
require 'rbkb/cli/dedump'

class TestCliDedump < Test::Unit::TestCase
  include CliTest

  def setup
    @cli_class = Rbkb::Cli::Dedump
    super()
    @tst_string = "this is a \x00\n\n\ntest\x01\x02\xff\x00"
    @tst_dump = <<_EOF_
00000000  74 68 69 73 20 69 73 20  61 20 00 0a 0a 0a 74 65  |this is a ....te|
00000010  73 74 01 02 ff 00                                 |st....|
00000016
_EOF_

    @bigtst_string = "\000\001\002\003\004\005\006\a\b\t\n\v\f\r\016\017\020\021\022\023\024\025\026\027\030\031\032\e\034\035\036\037 !\"\#.$.%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\177\200\201\202\203\204\205\206\207\210\211\212\213\214\215\216\217\220\221\222\223\224\225\226\227\230\231\232\233\234\235\236\237\240\241\242\243\244\245\246\247\250\251\252\253\254\255\256\257\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277\300\301\302\303\304\305\306\307\310\311\312\313\314\315\316\317\320\321\322\323\324\325\326\327\330\331\332\333\334\335\336\337\340\341\342\343\344\345\346\347\350\351\352\353\354\355\356\357\360\361\362\363\364\365\366\367\370\371\372\373\374\375\376\377" * 3
    @bigtst_dump = <<_EOF_
00000000  00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f  |................|
00000010  10 11 12 13 14 15 16 17  18 19 1a 1b 1c 1d 1e 1f  |................|
00000020  20 21 22 23 2e 24 2e 25  26 27 28 29 2a 2b 2c 2d  | !"#.$.%&'()*+,-|
00000030  2e 2f 30 31 32 33 34 35  36 37 38 39 3a 3b 3c 3d  |./0123456789:;<=|
00000040  3e 3f 40 41 42 43 44 45  46 47 48 49 4a 4b 4c 4d  |>?@ABCDEFGHIJKLM|
00000050  4e 4f 50 51 52 53 54 55  56 57 58 59 5a 5b 5c 5d  |NOPQRSTUVWXYZ[\]|
00000060  5e 5f 60 61 62 63 64 65  66 67 68 69 6a 6b 6c 6d  |^_`abcdefghijklm|
00000070  6e 6f 70 71 72 73 74 75  76 77 78 79 7a 7b 7c 7d  |nopqrstuvwxyz{|}|
00000080  7e 7f 80 81 82 83 84 85  86 87 88 89 8a 8b 8c 8d  |~...............|
00000090  8e 8f 90 91 92 93 94 95  96 97 98 99 9a 9b 9c 9d  |................|
000000a0  9e 9f a0 a1 a2 a3 a4 a5  a6 a7 a8 a9 aa ab ac ad  |................|
000000b0  ae af b0 b1 b2 b3 b4 b5  b6 b7 b8 b9 ba bb bc bd  |................|
000000c0  be bf c0 c1 c2 c3 c4 c5  c6 c7 c8 c9 ca cb cc cd  |................|
000000d0  ce cf d0 d1 d2 d3 d4 d5  d6 d7 d8 d9 da db dc dd  |................|
000000e0  de df e0 e1 e2 e3 e4 e5  e6 e7 e8 e9 ea eb ec ed  |................|
000000f0  ee ef f0 f1 f2 f3 f4 f5  f6 f7 f8 f9 fa fb fc fd  |................|
00000100  fe ff 00 01 02 03 04 05  06 07 08 09 0a 0b 0c 0d  |................|
00000110  0e 0f 10 11 12 13 14 15  16 17 18 19 1a 1b 1c 1d  |................|
00000120  1e 1f 20 21 22 23 2e 24  2e 25 26 27 28 29 2a 2b  |.. !"#.$.%&'()*+|
00000130  2c 2d 2e 2f 30 31 32 33  34 35 36 37 38 39 3a 3b  |,-./0123456789:;|
00000140  3c 3d 3e 3f 40 41 42 43  44 45 46 47 48 49 4a 4b  |<=>?@ABCDEFGHIJK|
00000150  4c 4d 4e 4f 50 51 52 53  54 55 56 57 58 59 5a 5b  |LMNOPQRSTUVWXYZ[|
00000160  5c 5d 5e 5f 60 61 62 63  64 65 66 67 68 69 6a 6b  |\]^_`abcdefghijk|
00000170  6c 6d 6e 6f 70 71 72 73  74 75 76 77 78 79 7a 7b  |lmnopqrstuvwxyz{|
00000180  7c 7d 7e 7f 80 81 82 83  84 85 86 87 88 89 8a 8b  ||}~.............|
00000190  8c 8d 8e 8f 90 91 92 93  94 95 96 97 98 99 9a 9b  |................|
000001a0  9c 9d 9e 9f a0 a1 a2 a3  a4 a5 a6 a7 a8 a9 aa ab  |................|
000001b0  ac ad ae af b0 b1 b2 b3  b4 b5 b6 b7 b8 b9 ba bb  |................|
000001c0  bc bd be bf c0 c1 c2 c3  c4 c5 c6 c7 c8 c9 ca cb  |................|
000001d0  cc cd ce cf d0 d1 d2 d3  d4 d5 d6 d7 d8 d9 da db  |................|
000001e0  dc dd de df e0 e1 e2 e3  e4 e5 e6 e7 e8 e9 ea eb  |................|
000001f0  ec ed ee ef f0 f1 f2 f3  f4 f5 f6 f7 f8 f9 fa fb  |................|
00000200  fc fd fe ff 00 01 02 03  04 05 06 07 08 09 0a 0b  |................|
00000210  0c 0d 0e 0f 10 11 12 13  14 15 16 17 18 19 1a 1b  |................|
00000220  1c 1d 1e 1f 20 21 22 23  2e 24 2e 25 26 27 28 29  |.... !"#.$.%&'()|
00000230  2a 2b 2c 2d 2e 2f 30 31  32 33 34 35 36 37 38 39  |*+,-./0123456789|
00000240  3a 3b 3c 3d 3e 3f 40 41  42 43 44 45 46 47 48 49  |:;<=>?@ABCDEFGHI|
00000250  4a 4b 4c 4d 4e 4f 50 51  52 53 54 55 56 57 58 59  |JKLMNOPQRSTUVWXY|
00000260  5a 5b 5c 5d 5e 5f 60 61  62 63 64 65 66 67 68 69  |Z[\]^_`abcdefghi|
00000270  6a 6b 6c 6d 6e 6f 70 71  72 73 74 75 76 77 78 79  |jklmnopqrstuvwxy|
00000280  7a 7b 7c 7d 7e 7f 80 81  82 83 84 85 86 87 88 89  |z{|}~...........|
00000290  8a 8b 8c 8d 8e 8f 90 91  92 93 94 95 96 97 98 99  |................|
000002a0  9a 9b 9c 9d 9e 9f a0 a1  a2 a3 a4 a5 a6 a7 a8 a9  |................|
000002b0  aa ab ac ad ae af b0 b1  b2 b3 b4 b5 b6 b7 b8 b9  |................|
000002c0  ba bb bc bd be bf c0 c1  c2 c3 c4 c5 c6 c7 c8 c9  |................|
000002d0  ca cb cc cd ce cf d0 d1  d2 d3 d4 d5 d6 d7 d8 d9  |................|
000002e0  da db dc dd de df e0 e1  e2 e3 e4 e5 e6 e7 e8 e9  |................|
000002f0  ea eb ec ed ee ef f0 f1  f2 f3 f4 f5 f6 f7 f8 f9  |................|
00000300  fa fb fc fd fe ff                                 |......|
00000306
_EOF_

  end # setup

  def test_file_input_arg
    with_testfile do |fname, tf|
      tf.write @tst_dump;  tf.close
      assert_equal 0, go_with_args([fname])
      assert_equal(@tst_string, @stdout_io.string)
    end
  end

  def test_stdin
    @stdin_io.write(@tst_dump) ; @stdin_io.rewind
    assert_equal 0, go_with_args
    assert_equal(@tst_string, @stdout_io.string)
  end


  def test_stdin_big
    @stdin_io.write(@bigtst_dump) ; @stdin_io.rewind
    assert_equal 0, go_with_args
    assert_equal(@bigtst_string, @stdout_io.string)
  end

  def test_bad_len
    len_dump = <<_EOF_
00000000  68 65  6c 75  |helu|
00000004  20 66  6f 6f  | foo|
00000008
_EOF_

    @stdin_io.write(len_dump) ; @stdin_io.rewind
    assert_equal 1, go_with_args(["-l", "2"])
    assert_equal("helu foo", @stdout_io.string)
  end

  def test_bad_len
    @stdin_io.write(@bigtst_dump) ; @stdin_io.rewind
    assert_equal 1, go_with_args(["-l", "-4"])
    assert_match(/length must be greater than zero/i, @stderr_io.string)
  end

  def test_bad_input
    @stdin_io.write("bad monkey") ; @stdin_io.rewind
    assert_equal 1, go_with_args([])
    assert_match(/parse error/i, @stderr_io.string)
  end

end
