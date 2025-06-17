# Copyright 2009 emonti at matasano.com
# See README.rdoc for license information
#

module Plug
  module Proxy
    include Base
    attr_accessor :target

    def initialize(transport, _target)
      @transport = transport
      @peers = ProxyPeerList.new(self)
      @kind = :proxy
    end
  end

  class ProxyPeerList < PeerList
    def add_peer(addr); end

    def add_peer_manually(*args); end
  end
end
