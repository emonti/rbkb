# Using the rbkb library's Monkey Patches

Much of rbkb is implemented as a bunch of monkeypatches to Array, String, 
Numeric and other base classes. If this suits your fancy (some people despise
monkeypatches, this is not their fancy) then you can 'require "rbkb"' from 
your irb sessions and own scripts. 

The monkey-patches were designed to let you approximate use of the rbkb shell 
commands from IRB or ruby scripts.

(My dirty secret: I use IRB for like... everything!). Here's what I dropped in
my `.irbrc`:
```ruby
require 'rbkb'

# this isn't strictly related to rbkb, but it's super handy on my mac
# for using the pasteboard (copy/paste) to get things in and out of irb
class String
  def pbcopy
    Open3.popen3('pbcopy') {|i, o, e,t| i.write(self)}
  end
end

def pbpaste
  `pbpaste`
end
```


Using the rbkb library in ruby will let you do things like the following (just 
some samples, see rdoc for more info).


# Do stuff with strings:

### sexify with hexify
  ```ruby
  foo = "helu foo"            #=> "helu foo"
  foo.hexify                  #=> "68656c7520666f6f"
  ```

### a little easier to read
  ```ruby
  foo.hexify(:delim => ' ')   #=> "68 65 6c 75 20 66 6f 6f"
  ```

### and back
  ```ruby
  _.unhexify                  #=> "helu foo"
  ```

### break out your hexdump -C styles
  ```ruby
  foodump = "helu foo".hexdump(:out => StringIO.new)
  #=> "00000000  68 65 6c 75 20 66 6f 6f  |helu foo|\n00000008\n"
  puts foodump
  # 00000000  68 65 6c 75 20 66 6f 6f  |helu foo|
  # 00000008
  # => nil
  foo.hexdump(:out => $stdout)
  # 00000000  68 65 6c 75 20 66 6f 6f  |helu foo|
  # 00000008
  # => nil
 ```

### reverse a hexdump

  ```ruby
  foodump.dehexdump             #=> "helu foo" `
  ```

### 'strings' like /usr/bin/strings
  ```ruby
  dat = File.read("/bin/ls")
  pp dat.strings
  # [[4132, 4143, :ascii, "__PAGEZERO\000"],
  #  [4188, 4195, :ascii, "__TEXT\000"],
  # ...
  #  [72427, 72470, :ascii, "*Apple Code Signing Certification Authority"],
  #  [72645, 72652, :ascii, "X[N~EQ "]]

  ## look for stuff in binaries
  dat.bgrep("__PAGEZERO")         #=> [[4132, 4142, "__PAGEZERO"], [40996, 41006, "__PAGEZERO"]]
  dat.bgrep(0xCAFEBABE.to_bytes)  #=> [[0, 4, "\312\376\272\276"]]
  ```

# Do stuff with numbers:

### Do you have an irrational distaste for pack/unpack? I do.
  ```ruby
  0xff.to_bytes                     #=> "\000\000\000\377"
  be = 0xff.to_bytes(:big)          #=> "\000\000\000\377"
  le = 0xff.to_bytes(:little)       #=> "\377\000\000\000"
  le16 = 0xff.to_bytes(:little,2)   #=> "\377\000"
  ```

### Strings can go the other way too
  ```ruby
  [be, le, le16].map {|n| n.dat_to_num(:big) } # default
  #=> [255, 4278190080, 65280]
  [be, le, le16].map {|n| n.dat_to_num(:little) }
  #=> [4278190080, 255, 255]
  ```

### Calculate padding for a given alignment
  ```ruby
  10.pad(16)     #=> 6
  16.pad(16)     #=> 0
  30.pad(16)     #=> 2
  32.pad(16)     #=> 0
  ```

# Interact with 'telson' and 'plugsrv' directly from IRB:

### In a separate window from your irb session do something like:

```bash 
$ telson rubyforge.com:80 -r
** TELSON-192.168.11.2:58118(TCP) Started
** BLITSRV-127.0.0.1:25195(TCP) Started
** TELSON-192.168.11.2:58118(TCP) CONNECTED TO PEER-205.234.109.19:80(TCP)
```

### You can blit any string from within IRB!

### A minor setup step is required... (I put this in my .irbrc)
```ruby
  Plug::Blit.blit_init              #=> nil
```

### now send some traffic
```ruby
  "GET / HTTP/1.0\r\n\r\n".blit                 #=> 28 
  ## Watch the basic HTTP request get made and responded to in the 
  ## other window.

  ("GET /"+ "A"*30 +" HTTP/1.0\r\n\r\n").blit   #=> 58 
  ## Watch the bogus HTTP request get made and responded to in the 
  ## other window.
```

# Some simple web encoding stuff:
```ruby
  xss="<script>alert('helu ' + document.cookie)</script"
```

### URL percent-encode stuff
```ruby
  xss.urlenc 
  #=> "%3cscript%3ealert%28%27helu%3a%20%27%20%2b%20document.cookie%29%3c%2fscript%3e"

  # and back
  _.urldec
  #=> "<script>alert('helu: ' + document.cookie)</script>"
```

### Base64 encode stuff
```ruby
  _.b64
  #=> "JTNjc2NyaXB0JTNlYWxlcnQlMjglMjdoZWx1JTNhJTIwJTI3JTIwJTJiJTIwZG9jdW1lbnQuY29va2llJTI5JTNjJTJmc2NyaXB0JTNl"

  # and back
  _.d64
  #=> "%3cscript%3ealert%28%27helu%3a%20%27%20%2b%20document.cookie%29%3c%2fscript%3e"
```

# Miscellaneous stuff:

```ruby
  # rediculous laziness!
  0x41.printable?         #=> true
  0x01.printable?         #=> false
```

### Make random gobbledygook and insults
```ruby
  "helu foo".randomize    #=> "ouofleh "
  "helu foo".randomize    #=> "foul hoe"
```

### Pretend (badly) to be smart:
```ruby
  # Cletus say's he's "sneaky"
  cletus = "my secrets are safe".xor("sneaky")
  #=> "\036\027E\022\016\032\001\v\021\022K\030\001\vE\022\n\037\026"
```

### Only not really so sneaky
```ruby
  cletus.xor "my secrets"     #=> "sneakysnea&a!x qxzb"
  cletus.xor "my secrets are" #=> "sneakysneakysn(k*ls"
  cletus.xor "sneaky"         #=> "my secrets are safe"
```

### Now make Cletus feel worse. With... MATH!
```ruby
  # (ala entropy scores)
  "A".entropy                               #=> 0.0
  "AB".entropy                              #=> 1.0
  "BC".entropy                              #=> 1.0
  (0..255).map {|x| x.chr}.join.entropy     #=> 8.0
```
### "You see, Cletus, you might have done this..."
```ruby
  sdat = "my secrets are very secret "*60
  require 'openssl'
  c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
  c.encrypt
  c.key = Digest::SHA1.hexdigest("sneaky")
  c.iv = c.random_iv
```

### "So, Cletus, when you say 'sneaky'... this is exactly how 'sneaky' you are"
```ruby
  c.update(sdat).entropy
  #=> 7.64800383393901
  sdat.xor("sneaky").entropy
  #=> 3.77687372599433
  sdat.entropy
  #=> 3.07487577558377
```

I recommend reading some of the markdown if you're interested in more of these 
little helpers.  Time permitting, I'll try to keep the docs useful and up 
to date. 
