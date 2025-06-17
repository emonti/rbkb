# rbkb

* http://emonti.github.com/rbkb

## DESCRIPTION:

Ruby BlackBag (rbkb)

A miscellaneous collection of command-line tools and ruby library helpers 
related to pen-testing and reversing. 

### Rationale

    Disclaimer: 
    Most of what's in the black bag came from a desire to do less typing.
    But there might be a few clever things that were added by accident.

rbkb is inspired by Matasano BlackBag (a set of similar tools written in C).

See: 
blackbag - http://github.com/emonti/rbkb/raw/master/reference/blackbag-0.9.1.tgz

Things go into the black bag as they are stolen (as a compliment!) or dreamed 
up, usually for simplifying some repetetive task or a desire for a new tool.

Along the way, some of tools in the blackbag spirit make their way into 'rbkb' 
that may or may not make it to 'bkb' right away (if ever). Similarly some of
the things in 'bkb' have not yet made it to 'rbkb' (and may not).


## SYNOPSIS:

### Command Line Tools

The tools almost all support '-h', but I'll admit this only goes so far.
See cli_usage.rdoc for usage and a bit of extra info on the various tools. 

When I get some spare time, I'll try and do up some examples of using all
the tools.


### Plug

Black Bag includes several tools for testing network protocols using plugboard
proxies. Users of the original Matasano BlackBag may be familiar with the
commands 'bkb replug', 'bkb telson', and 'bkb blit'.

Ruby BlackBag has a similar set of network tools:

* 'blit'  : Uses a simple homegrown OOB IPC mechanism (local socket) to 
  communicate with 'blit-capable' tools like telson and plugsrv and send
  data to network endpoints through them. Use 'blit' to send raw 
  messages to servers or clients then watch how they respond (see below).

* 'telson' : Similar to 'bkb telson'. Opens a TCP or UDP client connection 
  which is little more than a receiver for 'blit' messages. Use this to
  pretend to be a client and send raw messages to some service while observing 
  raw replies.

* 'plugsrv' : Similar to 'bkb replug'. Sits as a reverse TCP proxy between 
  one or more clients and a server. Accepts 'blit' messages which can be 
  directed at client or server ends of a conversation. The original 'replug'
  didn't do this, which makes plugsrv kindof neat.


### Monkey Patches

Much of rbkb is implemented as a bunch of monkeypatches to Array, String, 
Numeric and other base classes. If this suits your fancy (some people despise
monkeypatches, this is not their fancy) then you can 'require "rbkb"' from 
your irb sessions and own scripts. See 'lib_usage.rdoc' for more info.


## REQUIREMENTS:

* eventmachine >= 0.12.8


## INSTALL:

### Gem Installation

rbkb is available as a gem on gemcutter.org:

    gem install rbkb --source http://gemcutter.org


#### Gem Install Note

Installing the gem as root may be risky depending on your rubygems 
configuration so I don't really recommend using 'sudo gem install'. 
Worst case scenario I know of is I blew away my OSX-shipped '/usr/bin/crc32' 
this way. It was written in perl, so I considered this providence and didn't 
look back. But you may feel differently about 'rubygems' clobbering a file in 
/usr/bin.

When installing as a regular user, however, rubygems may stick rbkb's 
executable bin/* files somewhere unexpected. To find out where these are and 
either add them to your PATH or copy/symlink them somewhere else like 
/usr/local/bin/ do this:

    gem contents rbkb


### Manual installation:

  git clone git://github.com/emonti/rbkb.git
  cd rbkb
  rake gem:install


or ... you can also install manually without rubygems.

You can access the rbkb project at github. You'll want git installed:

  cp -r rbkb/lib/* /usr/lib/ruby/1.8/site_ruby/1.8 # or another ruby libdir
  cp bin/* ~/bin      # or wherever else in your PATH

Run this to generate docs with rdoc the same way the gem would have:

  rake doc:rdoc

## LICENSE:

(The MIT License) 

Copyright (c) 2009 Eric Monti, Matasano Security

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
