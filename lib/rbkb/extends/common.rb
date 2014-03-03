require "stringio"
require 'zlib'
require 'open3'
require 'enumerator'
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'

module Rbkb
  DEFAULT_BYTE_ORDER=:big
  HEXCHARS = [("0".."9").to_a, ("a".."f").to_a].flatten
end

