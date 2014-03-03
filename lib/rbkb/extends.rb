
require_relative 'extends/array'
require_relative 'extends/enumerable'
require_relative 'extends/float'
require_relative 'extends/numeric'
require_relative 'extends/object'
require_relative 'extends/string'
require_relative 'extends/symbol'

class String
  include Rbkb::Extends::String
end
