require 'rbkb/cli'
require 'rbkb/plug'
require 'eventmachine'


# Copyright 2009 emonti at matasano.com 
# See README.rdoc for license information
#
module Rbkb::Cli

  # Rbkb::Cli::Executable is an abstract class for creating command line
  # executables using the Ruby Black Bag framework.
  class PlugCli < Executable
    RX_HOST_AND_PORT = /^([\w\._-]+):(\d+)$/
    RX_PORT_OPT_ADDR = /^(?:([\w\._-]+):)?(\d+)$/

    attr_accessor :blit_addr, :blit_port, :blit_proto, 
                  :local_addr, :local_port, :transport,
                  :target_addr, :target_port

    def initialize(*args)
      super(*args) do |this|
        this.blit_addr ||= Plug::Blit::DEFAULT_IPADDR
        this.blit_port ||= Plug::Blit::DEFAULT_PORT
        this.transport ||= :TCP
        yield this if block_given?
      end

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
        Plug::UI::LOGCFG[:out] = File.open(o, "w") # XXX
      end

      arg.on("-q", "--quiet", "Turn off verbose logging") do
        Plug::UI::LOGCFG[:verbose] = false # XXX
      end

      arg.on("-d", "--dump-format=hex/raw", 
             "Output conversations in hexdump or raw") do |d|
        if m=/^(hex|raw)$/i.match(d)
          Plug::UI::LOGCFG[:dump] = m[1].downcase.to_sym # XXX
        else
          bail "Invalid dump format: #{d.inspect}"
        end
      end

      arg.on("-b", "--blit=ADDR:PORT", "Where to listen for blit") do |b|
        unless m=RX_PORT_OPT_ADDR.match(b)
          bail("Invalid blit address/port")
        end
        @blit_port = m[2].to_i
        @blit_addr = m[1] if m[1]
      end

      arg.on("-u", "--udp", "UDP mode") { @transport=:UDP }

      return arg
    end

    def parse_target_argument()
      unless (m = RX_HOST_AND_PORT.match(tgt=@argv.shift))
        bail "Invalid target: #{tgt}\n  Hint: use -h"
      end
      @target_addr = m[1]
      @target_port = m[2].to_i
      return m
    end
  end
end

