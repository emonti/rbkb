#----------------------------------------------------------------------
# Optional extensions based on dependencies below:
#----------------------------------------------------------------------

begin
  # magick signatures: attempt to identify a buffer with magic(5)
  # using the same library as file(1)
  #
  # Extends strings with a 'magic' method using FileMagic
  #
  # To use, do the following (for MacOS X)
  #
  # * need macports. and the macports version of 'file'
  #     $ sudo port install file
  #
  # * Install ruby-filemagic
  #     $ wget http://raa.ruby-lang.org/cache/filemagic/
  #
  # * untar and build
  #     $ cd <untarred-directory>
  #     $ env ARCHFLAGS="-arch i386" ruby extconf.rb --with-magic-dir=/opt/local
  #     $ make
  #     $ sudo make install
  #
  # Example:
  #
  #   irb(main):001:0> "foo".magic
  #   => "ASCII text, with no line terminators"
  #   irb(main):002:0> "\x1f\x8b".magic
  #   => "gzip compressed data"
  # 
  # XXX this is horribly slow on large chunks of data, but then most everything
  # in ruby is...
  require 'filemagic'
  class String
    @@fmagick = nil
    @@fmagick_opts = nil

    def magick(opts=FileMagic::MAGIC_NONE)
      if @@fmagick.nil? or @@fmagick_opts != opts
        @@fmagick = FileMagic.new(opts)
        @@fmagick_opts = opts
      end
      @@fmagick.buffer self
    end
  end
rescue
# nop
end


