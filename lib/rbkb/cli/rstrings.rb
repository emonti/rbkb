require 'rbkb/cli'

# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
# rstrings is Unix "strings" in ruby... with some extra stuff
class Rbkb::Cli::Rstrings < Rbkb::Cli::Executable
  def initialize(*args)
    super(*args) do |this|
      {
        :start_off => 0, 
        :end_off => -1, 
        :encoding => :both, 
        :minimum => 6,
        :align => nil,
        :indat => Array.new,
        :fnames => Array.new,
      }.each {|k,v| this.opts[k] ||= v }

      yield this if block_given?
    end
  end

  def make_parser()
    arg = super()
    arg.banner += " <file ... || blank for stdin>"

    arg.on("-s", "--start=OFFSET", "Start at offset") do |s|
      unless m=/^(?:(\d+)|0x([A-Fa-f0-9]+))$/.match(s)
        bail "invalid offset '#{s}'"
      end
      @opts[:start_off] = (m[2])? m[0].hex : m[0].to_i
    end

    arg.on("-e", "--end=OFFSET", "End at offset") do |e|
      unless m=/^(?:(\d+)|0x([A-Fa-f0-9]+))$/.match(e)
        bail "invalid offset '#{e}'"
      end
      @opts[:end_off] = (m[2])? m[0].hex : m[0].to_i
    end

    arg.on("-t", "--encoding-type=TYPE", 
      "Encoding: ascii/unicode/both (default=#{@opts[:encoding]})") do |t|
        @opts[:encoding] = t.to_sym
    end

    arg.on("-l", "--min-length=NUM", Numeric,
      "Minimum length of strings (default=#{@opts[:minimum]})") do |l|
        @opts[:minimum] = l
    end

    arg.on("-a", "--align=ALIGNMENT", Numeric, 
      "Match only on alignment (default=none)") do |a|
        (@opts[:align] = a) > 0 or bail "bad alignment '#{a}'"
    end

    return arg
  end

  def parse(*args)
    super(*args)
    if @opts[:indat].empty? and not @argv.empty?
      while a=@argv.shift
        @opts[:indat] << do_file_read(a)
        @opts[:fnames] << a
      end
    end

    parse_catchall()

    if @opts[:indat].empty?
      @opts[:indat] << @stdin.read() if @opts[:indat].empty?
      @opts[:fnames] << "[STDIN]"
    end
  end

  def go(*args)
    super(*args)

    start_off = @opts[:start_off]
    end_off   = @opts[:end_off]
    enc  = @opts[:encoding]
    min  = @opts[:minimum]
    align = @opts[:align]

    @opts[:pr_fnames]=true if @opts[:fnames].size > 1

    i=0
    while buf=@opts[:indat].shift
      buf[start_off..end_off].strings(
        :encoding => enc,
        :minimum => min,
        :align => align
      ) do |off, len, type, str|
        if @opts[:pr_fnames]
          @stdout << "#{@opts[:fnames][i]}:"
        end
        @stdout << "#{(off+start_off).to_hex.rjust(8,"0")}:"+
                   "#{(len+start_off).to_hex.rjust(8,"0")}:"+
                   "#{type.to_s[0,1]}:#{str.delete("\000").inspect}\n"
      end
      i+=1
    end

    self.exit(0)
  end
end

