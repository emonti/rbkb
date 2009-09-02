# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#

require 'socket'

module Plug

  class Peer
    attr_reader :addr, :transport, :name, :owner, :host, :port
    attr_accessor :mute

    def initialize(addr, owner)
      @addr = addr
      @owner = owner
      @transport = @owner.transport

      @port, @host = Socket.unpack_sockaddr_in(@addr)
      @name = "PEER-#{@host}:#{@port}(#{@transport})"
    end

    def say(dat, sender)
      UI.dump(sender.name, self.name, dat)

      if @transport == :UDP
        @owner.send_datagram(dat, @host, @port)
      else
        @owner.send_data(dat)
      end
    end

    def close
      @owner.unbind unless @transport == :UDP
    end
  end


  class PeerList < Array
    def initialize(owner, *args)
      @owner = owner
      @transport = @owner.transport
      
      super(*args)
    end

    def find_peer(addr)
      self.find {|p| p.addr == addr }
    end

    def add_peer(addr)
      self << Peer.new(addr, @owner)
      self.last
    end

    def add_peer_manually(host, port)
      addr = Socket.pack_sockaddr_in(port, host)
      return (find_peer(addr) || add_peer(addr))
    end

    def delete(addr)
      if p=find_peer(addr)
        p.close
        super(p)
      end
    end
  end
end
