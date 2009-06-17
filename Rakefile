# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'rbkb'

task :default => 'test:run'

PROJ.name = 'rbkb'
PROJ.authors = 'Eric Monti'
PROJ.email = 'emonti@matasano.com'
PROJ.description = 'Rbkb is a collection of ruby-based pen-testing and reversing tools. Inspired by Matasano Blackbag.'
PROJ.url = 'http://emonti.github.com/rbkb'
PROJ.version = Rbkb::VERSION
PROJ.rubyforge.name = 'rbkb'
PROJ.readme_file = 'README.rdoc'

PROJ.spec.opts << '--color'

PROJ.rdoc.opts << '--line-numbers'

#PROJ.rdoc.opts << '--diagram'
PROJ.notes.tags << "X"+"XX" # muhah! so we don't note our-self

# exclude rcov.rb and external libs from rcov report
PROJ.rcov.opts += [
  "--exclude",  "rcov.rb", 
  "--exclude", "eventmachine",
  "--exclude", "pcap_misc.rb",
  "--exclude", "pcaplet.rb"
]

depend_on 'eventmachine', '>= 0.12.0'

# EOF
