require 'rbkb/cli'
require 'rbkb/plug'
require 'rbkb/plug/feed_import'
require 'eventmachine'

# Copyright 2009 emonti at moatasano dot com
# See README.rdoc for license information
#
# This is a plug-board message feeder from static data sources.
# The "feed" handles messages opaquely and just plays them in the given 
# sequence.
#
# Feed can do the following things with minimum fuss: 
#   - Import messages from files, yaml, or pcap
#   - Inject custom/modified messages with "blit"
#   - Run as a server or client using UDP or TCP
#   - Bootstrap protocols without a lot of work up front
#   - Skip uninteresting messages and focus attention on the fun ones.
#   - Replay conversations for relatively unfamiliar protocols.
#   - Observe client/server behaviors using different messages at
#     various phases of a conversation.
#
# To-dos / Ideas:
#  - Unix Domain Socket support?
#  - more import options?
#  - dynamic feed elements?
#  - add/control feed elements while 'stepping'?
#

class Rbkb::Cli::Feed < Rbkb::Cli::Executable
  def initialize(*args)
    @local_addr = "0.0.0.0"
    @local_port = nil
    @listen = false
    @persist = false
    @transport = :TCP
    @svr_method = :start_server
    @cli_method = :bind_connect
    @blit_addr = Plug::Blit::DEFAULT_IPADDR
    @blit_port = Plug::Blit::DEFAULT_PORT


    ## Default options sent to the Feed handler
    @feed_opts = { 
      :close_at_end => false,
      :step => false,
      :go_first => false
    }

    super(*args)

    # TODO Plug::UI obviously need fixing. 
    # TODO It shouldn't be driven by constants for configuration
    Plug::UI::LOGCFG[:verbose] = true
    Plug::UI::LOGCFG[:dump] = :hex
    Plug::UI::LOGCFG[:out] = @stderr
  end

  def make_parser()
    arg = super()
    arg.banner += " host:port"

    arg.on("-o", "--output=FILE", "Output to file") do |o|
      Plug::UI::LOGCFG[:out] = File.open(o, "w")
    end

    arg.on("-l", "--listen=(ADDR:?)PORT", "Server - on port (and addr?)") do |p|
      if m=/^(?:([\w\._-]+):)?(\d+)$/.match(p)
        @local_addr = $1 if $1
        @local_port = $2.to_i
        @listen = true
      else
        raise "Invalid listen argument: #{p.inspect}"
      end
    end

    arg.on("-s", "--source=(ADDR:?)PORT", "Bind client on port and addr") do |p|
      if m=/^(?:([\w\.]+):)?(\d+)$/.match(p)
        @local_addr = $1 if $1
        @local_port = $2.to_i
      else
        bail("Invalid source argument: #{p.inspect}")
      end
    end

    arg.on("-b", "--blit=(ADDR:)?PORT", "Where to listen for blit") do |b|
      puts b
      unless(m=/^(?:([\w\._-]+):)?(\d+)$/.match(b))
        raise "Invalid blit argument: #{b.inspect}"
      end
      @blit_port = m[2].to_i
      @blit_addr = m[1] if m[1]
    end

    arg.on("-i", "--[no-]initiate", "Send the first message on connect") do |i|
      @feed_opts[:go_first] = i
    end

    arg.on("-e", "--[no-]end", "End connection when feed is exhausted") do |c|
      @feed_opts[:close_at_end] = c
    end
     
    arg.on("--[no-]step", "'Continue' prompt between messages") do |s|
      @feed_opts[:step] = s
    end

    arg.on("-u", "--udp", "Use UDP instead of TCP" ) do
      @transport = :UDP
    end

    arg.on("-r", "--reconnect", "Attempt to reconnect endlessly.") do
      @persist=true
    end

    arg.on("-q", "--quiet", "Suppress verbose messages/dumps") do
      Plug::UI::LOGCFG[:verbose] = false
    end

    arg.on("-Q", "--squelch-exhausted", "Squelch 'FEED EXHAUSTED' messages") do |s|
      @feed_opts[:squelch_exhausted] = true
    end

    arg.separator  "  Sources: (can be combined)"

    arg.on("-f", "--from-files=GLOB", "Import messages from raw files") do |f|
      @feed_opts[:feed] ||= []
      @feed_opts[:feed] += FeedImport.import_rawfiles(f)
    end

    arg.on("-x", "--from-hex=FILE", "Import messages from hexdumps") do |x|
      @feed_opts[:feed] ||= []
      @feed_opts[:feed] += FeedImport.import_dump(x)
    end

    arg.on("-y", "--from-yaml=FILE", "Import messages from yaml") do |y|
      @feed_opts[:feed] ||= []
      @feed_opts[:feed] += FeedImport.import_yaml(y)
    end

    arg.on("-p", "--from-pcap=FILE[:FILTER]", "Import messages from pcap") do |p|
      if /^([^:]+):(.+)$/.match(p)
        file = $1
        filter = $2
      else
        file = p
        filter = nil
      end

      @feed_opts[:feed] ||= []
      @feed_opts[:feed] += FeedImport.import_pcap(file, filter)
    end
  end

  def parse(*args)
    super(*args)

    if @transport == :UDP
      @svr_method = @cli_method = :open_datagram_socket
    end

    @local_port ||= 0
    # Prepare EventMachine arguments based on whether we are a client or server
    if @listen # server
      @meth = @svr_method
      addr_args = [@local_addr, @local_port]
      @feed_opts[:kind] = :server
      @feed_opts[:no_stop_on_unbind] = true
    else # client

      ## Get target/listen argument for client mode
      unless (m = /^([\w\.]+):(\d+)$/.match(tgt=@argv.shift))
        bail_args tgt
      end

      @target_addr = m[1]
      @target_port = m[2].to_i

      if @transport == :UDP
        addr_args = [@local_addr, @local_port]
      else
        addr_args = [@local_addr, @local_port, @target_addr, @target_port]
      end

      @meth = @cli_method
      @feed_opts[:kind] = :client
    end

    @feed_opts[:feed] ||= []

    @em_args=[ 
      @meth, 
      addr_args,
      Plug::ArrayFeeder, 
      @transport, 
      @feed_opts
    ].flatten

    parse_catchall()
  end


  def go(*args)
    super(*args)

    Plug::UI.verbose "** FEED CONTAINS #{@feed_opts[:feed].size} MESSAGES"

    ## Start the eventmachine
    loop do
      EventMachine::run do
        EventMachine.send(*@em_args) do |c|
          EventMachine.start_server(@blit_addr, @blit_port, Plug::Blit, :TCP, c)
          Plug::UI::verbose("** BLITSRV-#{@blit_addr}:#{@blit_port}(TCP) Started")

          # if this is a UDP client, we will always send the first message
          if [:UDP, :client] == [@transport, c.kind]
            peer = c.peers.add_peer_manually(@target_addr, @target_port)
            c.feed_data(peer)
            c.go_first = false
          end
        end
      end

      break unless @persist
      Plug::UI::verbose("** RECONNECTING")
    end

  end
end

