## Command Line Tools

Below is a list of the command line utilities with short descriptions and
usage information. Examples to come.

### b64

Base64 encode data supplied via an argument, file, or standard input.

Usage: b64 [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -l, --length LEN                 Output LEN chars per line


### bgrep

Binary grep. Prints 'inspected' matches and offset information.

  Usage: bgrep [options] <subject> <file | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -x, --[no-]hex                   Specify subject as hex (default: false)
    -r, --[no-]regex                 Specify subject as regex (default: false)
    -a, --align=BYTES                Only match on alignment boundary
    -n, --[no-]filename              Suppress prefixing of filenames.


### blit

Sends data through any plugboard that implements a Plug::Blit listener for
out-of band input.

See also: telson

  Usage: blit [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -t, --trans-protocol=PROTO       Blit transport protocol TCP/UDP
    -b, --blitsrv=ADDR:PORT          Where to send blit messages
    -i, --peer-index=IDX             Index for remote peer to receive
    -l, --list-peers                 Lists the peer array for the target
    -k, --kill                       Stops the remote event loop.


### c

Prints a character n-times.

  Usage: c 100 A; # print 100 A's'


### crc32

Generates a crc32 checksum for data provided via stdin or file

  Usage: crc32 [options]
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -r, --range=START[:END]          Start and optional end range
    -x, --hexrange=START[:END]       same, but in hex


### d64

Base64 decode an encoded chunk supplied via argument, file, or standard input.

Usage: d64 [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME


### dedump

Reverses a hexdump back to raw data. Designed to work with hexdumps created 
by Unix utilities like 'xxd' as well as 'hexdump -C'.

  Usage: dedump [options] <input-file | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -l, --length LEN                 Bytes per line in hexdump (default: 16)


### feed

This is a plug-board message feeder from static data sources.
The "feed" handles messages opaquely and just plays them as a server or
client in the given sequence.

Feed can do the following things with minimum fuss: 
* Import messages from files, yaml, or pcap
* Inject custom/modified messages with "blit"
* Run as a server or client using UDP or TCP
* Bootstrap protocols without a lot of work up front
* Skip uninteresting messages and focus attention on the fun ones.
* Replay conversations for relatively unfamiliar protocols.
* Observe client/server behaviors using different messages at 
  various phases of a conversation.

  Usage: feed [options] host:port
      -h, --help                       Show this message
      -v, --version                    Show version and exit
      -o, --output=FILE                Output to file
      -l, --listen=(ADDR:?)PORT        Server - on port (and addr?)
      -s, --source=(ADDR:?)PORT        Bind client on port and addr
      -b, --blit=(ADDR:)?PORT          Where to listen for blit
      -i, --[no-]initiate              Send the first message on connect
      -e, --[no-]end                   End connection when feed is exhausted
          --[no-]step                  'Continue' prompt between messages
      -u, --udp                        Use UDP instead of TCP
      -r, --reconnect                  Attempt to reconnect endlessly.
      -q, --quiet                      Suppress verbose messages/dumps
      -Q, --squelch-exhausted          Squelch 'FEED EXHAUSTED' messages
    Sources: (can be combined)
      -f, --from-files=GLOB            Import messages from raw files
      -x, --from-hex=FILE              Import messages from hexdumps
      -y, --from-yaml=FILE             Import messages from yaml
      -p, --from-pcap=FILE[:FILTER]    Import messages from pcap



### hexify

Converts a string or raw data to hex characters. Input can be supplied via 
stdin, a string argument, or a file (with -f).

  Usage: hexify [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -l, --length LEN                 Hexify in lines of LEN bytes
    -d, --delim=DELIMITER            DELIMITER between each byte
    -p, --prefix=PREFIX              PREFIX before each byte
    -s, --suffix=SUFFIX              SUFFIX after each byte


### len

Takes input from a blob of data and output it with its binary length prepended.

  Usage: len [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -n, --nudge INT                  Add integer to length
    -s, --size=SIZE                  Size of length field in bytes
    -x, --[no-]swap                  Swap endianness. Default=big
    -t, --[no-]total                 Include size word in size
    -l, --length=LEN                 Ignore all else and use LEN


### plugsrv

A blit-able reverse TCP proxy. Displays traffic hexdumps.

  Usage: plugsrv [options] target:tport[@[laddr:]lport]
    <target:tport>  = the address of the target service
    <@laddr:lport> = optional address and port to listen on

  Options:
      -o, --output FILE                send output to a file
      -l, --listen ADDR:PORT           optional listener address:port
                                       (default: 0.0.0.0:<tport>)
      -q, --[no-]quiet                 Suppress/Enable conversation dumps.
      -b, --blit ADDR:PORT             specify blit listener [address:]port
                                       (default: 127.0.0.1:25195)
          --[no-]target-tls            enable/disable TLS to target
          --[no-]server-tls            enable/disable TLS to clients
      -h, --help                       Show this message


### rex

  Lazy shortcut for ruby -e "..."

  All commandline arguments get smeared into a ruby statement via 'eval()'.


### rstrings

A utility much like Unix 'strings' -- implemented in ruby.

  Usage: rstrings [options] <file | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -s, --start=OFFSET               Start at offset
    -e, --end=OFFSET                 End at offset
    -t, --encoding-type=TYPE         Encoding: ascii/unicode/both (default=both)
    -l, --min-length=NUM             Minimum length of strings (default=6)
    -a, --align=ALIGNMENT            Match only on alignment (default=none)


### slice

Returns a slice from input. Just a shell interface to a string slice operation.

  Usage: slice [options] start (no args when using -r|-x)
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -r, --range=START[:END]          Start and optional end range
    -x, --hexrange=START[:END]       same, but in hex


### telson

This is an implementation of the original blackbag "telson" using ruby and 
eventmachine. 

Telson is for doing the following things with minimum fuss: 

* Run as a stubbed network client using UDP or TCP
* Use blit to communicate with the other side.
* Debug network protocols
* Observe client/server behaviors using different messages at various phases 
  of a conversation.

  Usage: telson [options] host:port
      -h, --help                       Show this message
      -v, --version                    Show version and exit
      -o, --output=FILE                Output to file
      -q, --quiet                      Turn off verbose logging
      -d, --dump-format=hex/raw        Output conversations in hexdump or raw
      -b, --blit=ADDR:PORT             Where to listen for blit
      -u, --udp                        UDP mode
      -S, --start-tls                  Initiate TLS
      -r, --reconnect                  Attempt to reconnect endlessly.
      -s, --source=(ADDR:?)PORT        Bind client on port and addr


### unhexify

unhexify converts a string of hex bytes back to raw data. Input can be 
supplied via stdin, a hex-string argument, or a file containing hex (use -f).

  Usage: unhexify [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -d, --delim DELIMITER            DELIMITER regex between hex chunks


### urldec

Decodes a url percent-encoded string. 
Input from stdin, file, or command-line argument.

  Usage: urldec [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -p, --[no-]plus                  Convert '+' to space (default is true)


### urlenc

Encodes data as a url percent-encoded string.
Input from stdin, file, or command-line argument.

  Usage: urlenc [options] <data | blank for stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME
    -p, --[no-]plus                  Convert spaces to '+' (default is false)


### xor

Repeating string xor. Takes input and XOR's it against a string. 
String can be provided in hex.

  Usage: xor [options] -k|-s <key> <data | stdin>
    -h, --help                       Show this message
    -v, --version                    Show version and exit
    -f, --file FILENAME              Input from FILENAME

  Key options (one of the following is required):
    -s, --strkey STRING              xor against bare STRING
    -x, --hexkey HEXSTR              xor against decoded HEXSTR