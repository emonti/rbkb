# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#

# Experimental!!!

require 'eventmachine'
require 'rbkb/plug'
require 'rbkb'

module Plug
  class PeerStub
    attr_reader :owner

    def initialize(owner)
      @owner = owner
    end

    def [](_junk)
      @owner
    end

    def []=(_junk)
      [@owner]
    end

    def peers
      nil
    end
  end

  module UnixDomain
    attr_accessor :mute, :peers

    def initialize
      @peers = PeerStub.new(self)
    end

    def name
      'a domain socket'
    end

    def receive_data(dat)
      puts 'Got:', dat.hexdump
    end

    def say(dat, sender)
      UI.dump(sender.name, name, dat)
      send_data(dat)
    end
  end
end

if $0 == __FILE__
  Plug::UI::LOGCFG[:verbose] = true

  b_addr = Plug::Blit::DEFAULT_IPADDR
  b_port = Plug::Blit::DEFAULT_PORT
  unless sock = ARGV.shift and ARGV.shift.nil?
    warn "usage: #{File.basename $0} unix_socket"
    exit 1
  end

  EventMachine.run do
    s = EventMachine.connect_unix_domain(sock, Plug::UnixDomain)
    Plug::UI.verbose("** UNIX-DOMAIN-#{sock.inspect} Started")

    # connect a blit channel:
    EventMachine.start_server(b_addr, b_port, Plug::Blit, :TCP, s)
    Plug::UI.verbose("** BLITSRV-#{b_addr}:#{b_port}(TCP) Started")
  end

end
