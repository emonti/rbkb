
extrafiles = %w{ README.rdoc usage.txt }

executables = %w{
  bin/b64 bin/bgrep bin/blit bin/c bin/crc32 bin/d64 bin/dedump bin/hexify 
  bin/len bin/rex bin/rstrings bin/slice bin/telson bin/unhexify bin/urldec 
  bin/urlenc bin/xor 
}

libfiles = %w{
  lib/rbkb.rb lib/rbkb/command_line.rb lib/rbkb/extends.rb lib/rbkb/plug.rb 
  lib/rbkb/plug/blit.rb lib/rbkb/plug/peer.rb lib/rbkb/plug/plug.rb 
}

SPEC = Gem::Specification.new do |s|
  s.name      = "rbkb"
  s.version   = "0.6.1.1"
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
                      '--line-numbers' ] + extrafiles

  s.add_dependency "eventmachine", ">= 0.12.2"
end

