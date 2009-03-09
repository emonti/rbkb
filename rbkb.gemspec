# Define several variables with filenames that require repeating

extrafiles = %w{
  README.rdoc
  cli_usage.rdoc
  lib_usage.rdoc
}

executables = %w{
  bin/b64
  bin/bgrep
  bin/blit
  bin/c
  bin/crc32
  bin/d64
  bin/dedump
  bin/hexify
  bin/len
  bin/plugsrv
  bin/rex
  bin/rstrings
  bin/slice
  bin/telson
  bin/unhexify
  bin/urldec
  bin/urlenc
  bin/xor
}

libfiles = %w{
  lib/rbkb.rb
  lib/rbkb/cli.rb
  lib/rbkb/cli/b64.rb
  lib/rbkb/cli/bgrep.rb
  lib/rbkb/cli/blit.rb
  lib/rbkb/cli/chars.rb
  lib/rbkb/cli/crc32.rb
  lib/rbkb/cli/d64.rb
  lib/rbkb/cli/dedump.rb
  lib/rbkb/cli/hexify.rb
  lib/rbkb/cli/len.rb
  lib/rbkb/cli/rstrings.rb
  lib/rbkb/cli/slice.rb
  lib/rbkb/cli/telson.rb
  lib/rbkb/cli/unhexify.rb
  lib/rbkb/cli/urldec.rb
  lib/rbkb/cli/urlenc.rb
  lib/rbkb/cli/xor.rb
  lib/rbkb/extends.rb
  lib/rbkb/plug/blit.rb
  lib/rbkb/plug/peer.rb
  lib/rbkb/plug/plug.rb
  lib/rbkb/plug/proxy.rb
  lib/rbkb/plug.rb
}

SPEC = Gem::Specification.new do |s|
  s.name      = "rbkb"
  s.version   = "0.6.2.1"
  s.author    = "Eric Monti"
  s.email     = "emonti@matasano.com"
  s.homepage  = "http://www.matasano.com"
  s.platform  = Gem::Platform::RUBY
  s.summary   = "Ruby Black-Bag"

  s.files         = extrafiles + executables + libfiles
  s.executables   = executables.map {|f| File.basename(f) }

  s.require_path  = "lib"
  s.autorequire   = "rbkb"

  s.has_rdoc      = true
  s.rdoc_options += [ '--title', "#{s.name} -- #{s.summary}",
                      '--main', 'README.rdoc',
                      '--line-numbers' ] + extrafiles

  s.add_dependency "eventmachine", ">= 0.12.0"
end

