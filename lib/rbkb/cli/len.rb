require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
# len prepends a binary length number in front of its input and outputs
# raw on STDOUT
class Rbkb::Cli::Len < Rbkb::Cli::Executable

  def initialize(*args)
    super(*args)

    # endianness pair. index 0 is always the default
    @endpair = [:big, :little]
    {
      :nudge => 0, 
      :size => 4, 
      :endian => @endpair[0],
    }.each {|k,v| @opts[k] ||= v}
  end


  def make_parser()
    super()
    add_std_file_opt(:indat)
    arg = @oparse
    arg.banner += " <data | blank for stdin>"

    arg.on("-n", "--nudge INT", Numeric, "Add integer to length") do |n|
      @opts[:nudge] += n
    end

    arg.on("-s", "--size=SIZE", Numeric, 
           "Size of length field in bytes") do |s|
      bail("Size must be greater than 0") unless (@opts[:size] = s) > 0
    end

    arg.on("-x", "--[no-]swap", 
           "Swap endianness. Default=#{@opts[:endian]}") do |x|
      @opts[:endian] = @endpair[(x)? 1 : 0]
    end

    arg.on("-t", "--[no-]total", "Include size word in size") do |t|
      @opts[:tot]=t
    end

    arg.on("-l", "--length=LEN", Numeric, 
           "Ignore all other flags and use static LEN") do |l|
      @opts[:static]=l
    end
  end


  def parse(*args)
    super(*args)
    @opts[:indat] ||= @argv.shift
    parse_catchall()
    @opts[:indat] ||= @stdin.read
  end


  def go(*args)
    super(*args)
    unless len=@opts[:static]
      len = @opts[:indat].size
      len += @opts[:size] if @opts[:tot]
      len += @opts[:nudge]
    end
    @stdout << len.to_bytes(@opts[:endian], @opts[:size]) << @opts[:indat]
  end

end

