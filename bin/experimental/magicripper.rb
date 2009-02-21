#!/usr/bin/env ruby
# (emonti at matasano) Matasano Security LLC 2008

require 'rbkb'
require 'rbkb/command_line'
require 'stringio'

include RBkB::CommandLine

first = 0
last = nil
chunksz = 8192

#------------------------------------------------------------------------------
# Init options and arg parsing
OPTS = {:len => 16}
arg = bkb_stdargs(nil, OPTS)

arg.banner += " <input-file | blank for stdin>"

arg.on("-s", "--start=OFF", Numeric, "Start at offset") {|s| first=s}
arg.on("-e", "--end=OFF", Numeric, "End at offset") {|e| last=e}
arg.on("-c", "--chunks=SIZE", Numeric, "Size at a time") {|c| chunksz=c}

begin
  #----------------------------------------------------------------------------
  # Parse arguments

  arg.parse!(ARGV)

  inp = nil

  if a=ARGV.shift
    inp=File.open(a, "rb") rescue "Error: Can't open file '#{a}'"
  end

  # catchall
  if ARGV.length != 0 
      raise "bad arguments - #{ARGV.join(' ')}"
  end

  inp ||= StringIO.new(STDIN.read())

  #----------------------------------------------------------------------------
  # Do stuff

  off = inp.pos = first
  until inp.eof? or (last and inp.pos >= last)
    off = inp.pos
    dat = inp.read(chunksz)

    ## XXX uncomment the next line to use a non-lib find call to Unix
    #mg = dat.pipe_magick.chomp
    mg = dat.magick.chomp

    inp.pos = off + 1
    puts "#{off.to_hex(4)}: #{mg}" unless mg == "data"
    GC.start
  end
rescue
  bail $!
end

