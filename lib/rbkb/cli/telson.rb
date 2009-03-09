require 'rbkb/cli'
require 'rbkb/plug'
require 'eventmachine'


# This is an implementation of the original blackbag "telson" around 
# ruby and eventmachine. 
#
# Telson can do the following things with minimum fuss: 
#   - Run as a server or client using UDP or TCP
#   - Debugging network protocols
#   - Observe client/server behaviors using different messages at
#     various phases of a conversation.
#
class Rbkb::Cli::Telson < Rbkb::Cli::Executable

  def initialize(*args)
    super(*args)
    @b_addr = Plug::Blit::DEFAULT_IPADDR
    @b_port = Plug::Blit::DEFAULT_PORT
    @srced = @persist = false
    @s_addr = "0.0.0.0"
    @s_port = 0
    @proto = :TCP

    # XXX TODO Plug::UI obviously need fixing. It shouldn't be a module
    # with constants for configuration
    Plug::UI::LOGCFG[:verbose] = true
    Plug::UI::LOGCFG[:dump] = :hex
    Plug::UI::LOGCFG[:out] = @stderr
  end


  def make_parser()
    arg = super()
    arg.banner += " host:port"

    arg.on("-u", "--udp", "UDP mode") do
      @proto=:UDP
    end

    arg.on("-b", "--blit=ADDR:PORT", "Where to listen for blit") do |b|
      unless m=/^(?:([\w\.]+):)?(\d+)$/.match(b)
        bail("Invalid blit address/port")
      end
      @b_port = m[2].to_i
      @b_addr = m[1] if m[1]
    end

    arg.on("-o", "--output=FILE", "Output to file instead of screen") do |f|
      Plug::UI::LOGCFG[:out] = File.open(f, "w") # XXX
    end

    arg.on("-q", "--quiet", "Turn off verbose logging") do
      Plug::UI::LOGCFG[:verbose] = false # XXX
    end

    arg.on("-r", "--reconnect", "Attempt to reconnect endlessly.") do
      @persist=true
    end

    arg.on("-s", "--source=(ADDR:?)PORT", "Bind on port (and addr?)") do |p|
      if m=/^(?:([\w\.]+):)?(\d+)$/.match(p)
        @s_addr = $1 if $1
        @s_port = $2.to_i
        @srced = true
      else
        bail("Invalid listen argument: #{p.inspect}")
      end
    end
  end


  def parse(*args)
    super(*args)

    # Get target argument
    unless (m = /^([\w\.]+):(\d+)$/.match(@argv.shift)) and @argv.shift.nil?
      bail "Invalid target #{arg}"
    end

    @t_addr = m[1]
    @t_port = m[2].to_i
  end


  def go(*args)
    super(*args)

    loop do
      EventMachine.run {
        if @proto == :TCP
          bail("Sorry: --source only works with UDP.") if @srced

          c=EventMachine.connect(@t_addr, @t_port, Plug::Telson, @proto)

        elsif @proto == :UDP
          c=EventMachine.open_datagram_socket(
            @s_addr, @s_port, Plug::Telson, @proto
          )
          c.peers.add_peer_manually(@t_addr, @t_port)

        ### someday maybe raw or others?
        else
          raise "bad protocol"
        end

        EventMachine.start_server(@b_addr, @b_port, Plug::Blit, :TCP, c)
        Plug::UI::verbose("** BLITSRV-#{@b_addr}:#{@b_port}(TCP) Started") # XXX
      }
      break unless @persist
      Plug::UI::verbose("** RECONNECTING") # XXX
    end
  end
end

