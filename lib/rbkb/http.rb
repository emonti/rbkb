require "rbkb"
require "rbkb/http/base.rb"
require "rbkb/http/headers.rb"

# ???Why???? would anyone create their own HTTP implementation in ruby with 
# so many options out there? Short answer: Net:HTTP and others just don't cut 
# it in lots of edge cases. I needed something I could control completely.

