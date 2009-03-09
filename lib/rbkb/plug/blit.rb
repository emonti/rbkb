
module Plug
  module Blit
    include Base

    DEFAULT_IPADDR = "127.0.0.1"
    DEFAULT_PORT = 25195
    DEFAULT_PROTOCOL = :TCP

    OPCODES = {
      0 => :squelch,
      1 => :unsquelch,
      2 => :delete,
      5 => :sendmsg,
      6 => :list_peers,

      0xfe => :clear,
      0xff => :kill,
    }

    attr_accessor :kind

    def initialize(transport, slave)
      super(transport)

      @kind = :blitsrv
      @slave = slave
      @peers = slave.peers
      initbuf
    end

    def post_init
      # override so we don't get unneccessary "Start" message from Base
    end

    def unbind
      # override so we don't get unneccessary "closed" message from Base
    end


    ### Blit protocol stuff
    SIG = "BLT"

    # (re)initializes the blit buffer
    def initbuf
      @buf = StringIO.new
    end
    
    def receive_data dat
      return unless (@buf.write(dat) > SIG.size) or (@buf.pos > (SIG.size + 1))

      @buf.rewind

      return unless @buf.read(SIG.size) == SIG and
                    op = OPCODES[ @buf.read(1)[0] ]

      initbuf if self.send(op)
    end
    

    def self.blit_header(op)
      return nil unless opno = OPCODES.invert[op]
      SIG + opno.chr
    end

    def mute
      unless ( peerno=@buf.read(2) and peerno.size == 2 and
               peer=@peers[peerno.dat_to_num(:big)] )

        UI.log "** BLIT-ERROR(Malformed or missing peer for mute)"
        return true
      end
    end

    def self.make_mute(peerno)
      self.blit_header(:squelch) +
        peerno.to_bytes(:big, 2)
    end

    def unmute
      unless ( peerno=@buf.read(2) and peerno.size == 2 and
               peer=@peers[peerno.dat_to_num(:big)] )
        UI.log "** BLIT-ERROR(Malformed or missing peer for unmute)"
        return true
      end
    end

    def self.make_squelch(peerno)
      self.blit_header(:squelch) +
        peerno.to_bytes(:big, 2)
    end

    def sendmsg
      unless peerno=@buf.read(2) and peerno.size == 2 and
             bufsiz=@buf.read(4) and bufsiz.size == 4
        UI.log "** BLIT-ERROR(Malformed sendmsg)"
        return true
      end

      peerno = peerno.dat_to_num(:big)
      bufsiz = bufsiz.dat_to_num(:big)

      if (rdat=@buf.read(bufsiz)).size == bufsiz
        if peer=@peers[peerno]
          peer.say(rdat, self)
          return true
        else
          UI.log "** BLIT-ERROR(Invalid peer index #{peerno})"
          return true
        end
      else
        return nil
      end
    end

    # Blit packed message format is (SUBJECT TO CHANGE):
    #   "BLT"
    #   char   opcode
    #   uint16be idx   = index of slave peer to send to
    #   uint32le size  = length of data
    #   str      data
    def self.make_sendmsg(idx, dat)
      self.blit_header(:sendmsg) +
        idx.to_bytes(:big, 2) + 
        dat.size.to_bytes(:big, 4) + 
        dat
    end

    def kill
      UI.log("** BLIT-KILL - Received shutdown command")
      EM.stop
    end

    def self.make_kill(idx=nil)
      self.blit_header(:kill)
    end

    def clear
      @peers.each { |p| p.close }
      @peers.replace []
    end

    def self.make_clear
      self.blit_header(:clear)
    end

    def delete(peerno)
      @peers.delete(peerno)
    end

    def self.make_delete(idx=0)
      self.blit_header(:delete) +
        idx.to_bytes(:big, 2)
    end

    def list_peers
      UI.log("** BLIT-LISTPEERS - Received list peers command")

      @peers.each_index {|i| UI.log "**   #{i} - #{@peers[i].name}"}
      UI.log("** BLIT-LISTPEERS-END - End of peer list")
    end

    def self.make_list_peers
      self.blit_header(:list_peers)
    end

    #----------------------------------------------------------------------
    # Convenience methods for blit clients
    #----------------------------------------------------------------------

    BLIT_HANDLERS = {
      :TCP => lambda {|msg| 
        s=TCPSocket.new(@blit_addr, @blit_port)
        wl=s.write(msg)
        s.close
        return wl
      },
      :UDP => lambda {|msg|
        s=UDPSocket.new
        wl=s.send( msg, 0, @blit_addr, @blit_port)
        s.close
        return wl
      }
    }

    def self.blit_init(opts={})
      @blit_addr = (opts[:addr] || DEFAULT_IPADDR)
      @blit_port = (opts[:port] || DEFAULT_PORT)
      proto = (opts[:protocol] || DEFAULT_PROTOCOL)
      @blit_handler = BLIT_HANDLERS[ proto ]
      raise "invalid blit transport protocol" unless @blit_handler
    end

    def self.initialized?
      @blit_addr and @blit_port and @blit_handler
    end

    def self.blit_send(data, idx=0)
      msg = make_sendmsg(idx, data)
      blit_raw(msg)
    end

    def self.blit_raw(buf)
      raise "use blit_init first!" unless self.initialized?
      @blit_handler.call buf
    end

  end  # of module Blit


end # of module Plug

class String
  #----------------------------------------------------------------------
  # A Blit sender convenience method for strings
  def blit(idx=0)
    raise "blit must be initialized with blit_init" unless Plug::Blit.initialized?
    Plug::Blit.blit_send(self, idx)
  end
end
