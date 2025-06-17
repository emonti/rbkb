require 'rbkb/cli'
require 'rbkb/plug'

# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#
# blit is for use with any of the "plug" tools such as telson, feed, blitplug.
# It is used to send data over a socket via their OOB blit listener.
class Rbkb::Cli::Blit < Rbkb::Cli::Executable
  attr_accessor :blit_msg

  def initialize(*args)
    super(*args)
    {
      b_addr: Plug::Blit::DEFAULT_IPADDR,
      b_port: Plug::Blit::DEFAULT_PORT,
      bp_proto: :TCP,
      b_peeridx: 0
    }.each { |k, v| @opts[k] ||= v }
  end

  def make_parser
    super()
    add_std_file_opt(:indat)
    arg = @oparse

    arg.banner += ' <data | blank for stdin>'

    arg.on('-t', '--trans-protocol=PROTO',
           'Blit transport protocol TCP/UDP') do |t|
      @opts[:b_proto] = t.upcase.to_sym
    end

    arg.on('-S', '--starttls', 'Start TLS handshake for the peer index (-i)') do |_s|
      @blit_msg = Plug::Blit.make_starttls(@opts[:b_peeridx])
    end

    arg.on('-b', '--blitsrv=ADDR:PORT',
           'Where to send blit messages') do |b|
      unless (m = /^(?:([\w.]+):)?(\d+)$/.match(b))
        bail 'invalid blit address/port'
      end
      @opts[:b_port] = m[2].to_i
      @opts[:b_port] = m[1] if m[1]
    end

    arg.on('-i', '--peer-index=IDX', Numeric,
           'Index for remote peer to receive') do |i|
      @opts[:b_peeridx] = i
    end

    arg.on('-l', '--list-peers', 'Lists the peer array for the target') do
      @blit_msg = Plug::Blit.make_list_peers
    end

    arg.on('-k', '--kill', 'Stops the remote event loop.') do
      @blit_msg = Plug::Blit.make_kill
    end

    arg
  end

  def parse(*args)
    super(*args)

    return if @blit_msg

    if @opts[:indat].nil?
      @opts[:indat] = @argv.length > 0 ? @argv.join(' ') : @stdin.read
    end
    @blit_msg = Plug::Blit.make_sendmsg(@opts[:b_peeridx], @opts[:indat])
  end

  def go(*args)
    super(*args)

    begin
      Plug::Blit.blit_init(
        addr: @opts[:b_addr],
        port: @opts[:b_port],
        protocol: @opts[:b_proto]
      )

      Plug::Blit.blit_raw(@blit_msg)
    rescue StandardError
      bail($!)
    end

    self.exit(0)
  end
end
