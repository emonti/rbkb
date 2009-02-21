require 'yaml'

## This requires the 'ruby-pcap' library from:
##   http://raa.ruby-lang.org/project/pcap/
## ... which is old and krufty...
$VERBOSE=nil
require 'pcaplet'
$VERBOSE=false

require 'rbkb'

module FeedImport

  # Imports an array from pcap
  def import_pcap(file, filter=nil)
    ret = Array.new
    pcap = Pcap::Capture.open_offline(file)
    pcap.setfilter filter if filter
    pcap.each_packet do |pkt|
      if ( (pkt.udp? and dat=pkt.udp_data) or 
           (pkt.tcp? and dat=pkt.tcp_data and not dat.empty?)
         ) 
           ret <<  dat 
      end
    end
    return ret
  end
  module_function :import_pcap


  # Imports an array from yaml
  def import_yaml(file)
    unless ( ret = YAML.load_file(file) ).kind_of? Array
      raise "#{file.inspect} did not provide an array"
    end
    return ret
  end
  module_function :import_yaml


  # Imports from hexdumps separated by "%" and merged by ','
  def import_dump(file)
    ret = []
    dat = File.read(file)
    dat.strip.split(/^%$/).each do |msg|
      ret << ""
      msg.strip.split(/^,$/).each do |chunk|
        ret[-1] << chunk.strip.dehexdump
      end
    end
    return ret
  end
  module_function :import_dump

  # Imports raw messages in files by a glob pattern (i.e. /tmp/foo/msgs.*)
  # Manage filenames so that they're in the right order on import.
  # See Dir.glob for valid globbing patterns.
  def import_rawfiles(glob_pat)
    Dir.glob(glob_pat).map { |f| File.read(f) }
  end
  module_function :import_rawfiles
end

