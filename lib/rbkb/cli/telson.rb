require 'rbkb/plug/cli'

# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#
# This is an implementation of the original blackbag "telson" around
# ruby and eventmachine.
#
# Telson can do the following things with minimum fuss:
#   - Run as a "stubbed" network client using UDP or TCP
#   - Debugging network protocols
#   - Observe client/server behaviors using different messages at
#     various phases of a conversation.
#
class Rbkb::Cli::Telson < Rbkb::Cli::PlugCli

  def initialize(*args)
    super(*args) do |this|
      this.local_addr = "0.0.0.0"
      this.local_port = 0
    end

    @persist = false
  end


  def make_parser()
    arg = super()

    arg.on("-r", "--reconnect", "Attempt to reconnect endlessly.") do
      @persist=true
    end

    arg.on("-s", "--source=(ADDR:?)PORT", "Bind client on port and addr") do |p|
      if m=/^(?:([\w\.]+):)?(\d+)$/.match(p)
        @local_addr = $1 if $1
        @local_port = $2.to_i
      else
        bail("Invalid source argument: #{p.inspect}")
      end
    end
  end


  def parse(*args)
    super(*args)

    parse_target_argument()
    parse_catchall()
  end


  def go(*args)
    super(*args)
    loop do
      EventMachine.run {
        if @transport == :TCP

          c=EventMachine.bind_connect( @local_addr,
                                       @local_port,
                                       @target_addr,
                                       @target_port,
                                       Plug::Telson,
                                       @transport,
                                       @plug_opts )
        elsif @transport == :UDP
          c=EventMachine.open_datagram_socket( @local_addr,
                                               @local_port,
                                               Plug::Telson,
                                               @transport,
                                               @plug_opts )

          c.peers.add_peer_manually(@target_addr, @target_port)

        ### someday maybe raw or others?
        else
          raise "bad transport protocol"
        end
        EventMachine.start_server(@blit_addr, @blit_port, Plug::Blit, @blit_proto, c)
        Plug::UI::verbose("** BLITSRV-#{@blit_addr}:#{@blit_port}(TCP) Started") # XXX
      }
      break unless @persist
      Plug::UI::verbose("** RECONNECTING") # XXX
    end
  end
end

