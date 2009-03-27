
# ???Why???? would anyone create their own HTTP implementation in ruby with 
# so many options out there? Short answer: Net:HTTP and others just don't cut 
# it in lots of edge cases. I needed something I could control completely.

module Rbkb
  module Http
    VERSION = "0.0.2"
  end
end

require "rbkb/http/common.rb"
require "rbkb/http/base.rb"
require "rbkb/http/request.rb"
require "rbkb/http/response.rb"
require "rbkb/http/headers.rb"
require "rbkb/http/body.rb"
require "rbkb/http/parameters.rb"


