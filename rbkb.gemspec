# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rbkb}
  s.version = "0.6.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Monti"]
  s.date = %q{2009-03-12}
  s.description = %q{emonti@matasano.com}
  s.email = %q{emonti@matasano.com}
  s.executables = ["b64", "bgrep", "blit", "c", "crc32", "d64", "dedump", "hexify", "len", "plugsrv", "rex", "rstrings", "slice", "telson", "unhexify", "urldec", "urlenc", "xor"]
  s.extra_rdoc_files = ["History.txt", "README.rdoc", "bin/b64", "bin/bgrep", "bin/blit", "bin/c", "bin/crc32", "bin/d64", "bin/dedump", "bin/hexify", "bin/len", "bin/plugsrv", "bin/rex", "bin/rstrings", "bin/slice", "bin/telson", "bin/unhexify", "bin/urldec", "bin/urlenc", "bin/xor", "cli_usage.rdoc", "lib_usage.rdoc"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "bin/b64", "bin/bgrep", "bin/blit", "bin/c", "bin/crc32", "bin/d64", "bin/dedump", "bin/hexify", "bin/len", "bin/plugsrv", "bin/rex", "bin/rstrings", "bin/slice", "bin/telson", "bin/unhexify", "bin/urldec", "bin/urlenc", "bin/xor", "cli_usage.rdoc", "doctor-bag.jpg", "lib/rbkb.rb", "lib/rbkb/cli.rb", "lib/rbkb/cli/b64.rb", "lib/rbkb/cli/bgrep.rb", "lib/rbkb/cli/blit.rb", "lib/rbkb/cli/chars.rb", "lib/rbkb/cli/crc32.rb", "lib/rbkb/cli/d64.rb", "lib/rbkb/cli/dedump.rb", "lib/rbkb/cli/hexify.rb", "lib/rbkb/cli/len.rb", "lib/rbkb/cli/rstrings.rb", "lib/rbkb/cli/slice.rb", "lib/rbkb/cli/telson.rb", "lib/rbkb/cli/unhexify.rb", "lib/rbkb/cli/urldec.rb", "lib/rbkb/cli/urlenc.rb", "lib/rbkb/cli/xor.rb", "lib/rbkb/extends.rb", "lib/rbkb/plug.rb", "lib/rbkb/plug/blit.rb", "lib/rbkb/plug/feed_import.rb", "lib/rbkb/plug/peer.rb", "lib/rbkb/plug/plug.rb", "lib/rbkb/plug/proxy.rb", "lib/rbkb/plug/unix_domain.rb", "lib_usage.rdoc", "spec/rbkb_spec.rb", "spec/spec_helper.rb", "tasks/ann.rake", "tasks/bones.rake", "tasks/gem.rake", "tasks/git.rake", "tasks/notes.rake", "tasks/post_load.rake", "tasks/rdoc.rake", "tasks/rubyforge.rake", "tasks/setup.rb", "tasks/spec.rake", "tasks/svn.rake", "tasks/test.rake", "test/test_cli_b64.rb", "test/test_cli_crc32.rb", "test/test_cli_d64.rb", "test/test_cli_hexify.rb", "test/test_cli_urldec.rb", "test/test_cli_urlenc.rb", "test/test_helper.rb", "test/test_rbkb.rb"]
  s.has_rdoc = true
  s.homepage = %q{rbkb.rubyforge.org}
  s.rdoc_options = ["--line-numbers", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rbkb}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{emonti@matasano}
  s.test_files = ["test/test_cli_b64.rb", "test/test_cli_crc32.rb", "test/test_cli_d64.rb", "test/test_cli_hexify.rb", "test/test_cli_urldec.rb", "test/test_cli_urlenc.rb", "test/test_helper.rb", "test/test_rbkb.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.0"])
      s.add_development_dependency(%q<bones>, [">= 2.4.2"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.0"])
      s.add_dependency(%q<bones>, [">= 2.4.2"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.0"])
    s.add_dependency(%q<bones>, [">= 2.4.2"])
  end
end
