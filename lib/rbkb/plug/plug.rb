# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#

require "rbkb/plug/peer.rb"
require 'stringio'
require 'socket'


module Plug
  module UI
    LOGCFG = {:out => STDERR, :dump => :hex}

    def self.prompt(*msg); STDERR.puts msg ; STDIN.gets ; end

    def self.log(*msg); LOGCFG[:out].puts msg ; end

    def self.verbose(*msg); LOGCFG[:out].puts msg if LOGCFG[:verbose] ; end

    def self.debug(*msg); LOGCFG[:out].puts msg if LOGCFG[:debug] ; end

    def self.logmsg(name, msg)
      log "%% #{name} - #{msg}"
    end

    def self.dump(from, to, dat)
      if dump=LOGCFG[:dump]
        log "%% #{from} SAYS TO #{to} LEN=#{dat.size}" if LOGCFG[:verbose]
        case dump
        when :hex
          dat.hexdump(:out => LOGCFG[:out])
        when :raw
          LOGCFG[:out].puts dat
        else
          LOGCFG[:out].puts dat
        end
        log "%%" if LOGCFG[:verbose]
      end
    end
  end


  module Base
    attr_accessor :peers, :transport, :kind, :tls, :tls_opts, :no_stop_on_unbind

    def initialize(transport, opts={})
#      raise "Invalid transport #{transport.inspect}" unless (:UDP, :TCP).include?(transport)
      @transport = transport
      @peers = PeerList.new(self)

      opts.each_pair do |k,v|
        accessor = k.to_s + "="
        if self.respond_to?(accessor)
          self.send(accessor, v)
        else
          raise "Bad attribute: #{k}"
        end
      end
    end

    def name
      sn = get_sockname
      addr = sn ? Socket.unpack_sockaddr_in(sn).reverse.join(":") : "PENDING"
      "#{kind.to_s.upcase}-#{addr}(#{@transport})"
    end


    # plug_peer creates a peering association for a given peer based on 
    # get_peername. The existing or newly created peer object is returned.
    def plug_peer
      paddr = get_peername
      peer = (@peers.find_peer(paddr) || @peers.add_peer(paddr) )
    end


    # plug_receive is used by receive_data to divert incoming messages. 
    # The "peer" is added if it is not already present. This instance 
    # will check whether # a peer is "muted" and will return the peer if not.
    # This method can be overriden by child classes to implement additional
    # checks. It receives "dat" so that such checks can optionally make
    # forwarding decisions based on message data contents as well.
    #
    # Returns: 
    #   - nil : indicates that the message should be stifled
    #   - A peer object : indicates that the message should be processed 
    #     further
    def plug_receive(dat)
      peer = plug_peer
      return peer unless peer.mute
    end
   
    # This instance of the say method is an abstract stub and just 
    # "dumps" the message. It should be overridden and optionally called 
    # with super() if you actually want to do anything useful when 
    # incoming messages are received.
    def say(dat, sender)
      UI.dump(sender.name, self.name, dat)
    end

    def post_init
      UI.verbose "** #{name} Started"
      if @kind==:server and peer=plug_peer
        UI.log "** #{name} CONNECTED TO #{peer.name}"
        if tls
          start_tls(tls_opts || {})
        end
      end
    end

    def receive_data(dat)
      if peer=plug_receive(dat)
        say(dat, peer) 
      end
      return peer
    end

    def connection_completed
      peer = plug_peer
      UI.log "** #{name} CONNECTED TO #{peer.name}"
      if tls
        start_tls(tls_opts || {})
      end
      return peer
    end

    def unbind
      UI.log "** Connection " + ((@peers.empty?)? "refused." : "closed.")
      unless @no_stop_on_unbind
        UI.log "STOPPING!!"
        EM.stop  
      end
    end
  end


  # An abstract module to implement custom servers for any protocol
  # incoming messages are diverted to 'process(dat, sender)' which takes
  # a block, the yields to which are messages to respond with
  module UdpServer 
    include Base

    def kind ; :server ; end

    def say(dat, sender)
      super(dat, sender)

      if self.respond_to? :process
        self.send(:process, dat, sender) { |rply| sender.say(rply, self) }
      end
    end
  end



  # Telson is just a receiver for blit
  module Telson
    include Base
    def kind ; :telson ; end
  end


  # Uses an array of static messages as a datasource for opaque protocol
  # messages. Useful as a generic blit-able loop
  module ArrayFeeder
    include Base
    attr_accessor :pos, :feed, :step, :close_at_end, :go_first, 
                  :squelch_exhausted
    
    def initialize(*args)
      super(*args)

      @pos ||= 0
      @feed ||= []

      raise "feed must be enumerable" unless Enumerable === @feed
    end
    
    def go
      if @go_first
        feed_data
        @go_first = false
      end
    end

    def connection_completed
      peer=super()
      go if @go_first
      return peer
    end

    
    def say(dat, sender)
      super(dat, sender)
      if @step
        EventMachine.defer(
          proc { UI.prompt ">> Hit [enter] to continue at #{@pos}:" },
          proc {|x| feed_data }
        )
      else
        feed_data
      end
    end

    def feed_data(dst=plug_peer)
      unless dat=@feed[@pos]
        UI.log "** FEED EXHAUSTED" unless @squelch_exhausted
        return nil
      end

      dst.say dat.to_s, self

      if (@pos += 1) >= @feed.size and @close_at_end
        close_connection_after_writing
      end
    end

  end # ArrayFeeder
end # Plug

