require 'rbkb/extends/common'

module Rbkb
  module Extends
    module Float
      def log2
        Math.log(self) / Math.log(2)
      end
    end
  end
end

# float is a weird "Type"
class Float
  include Rbkb::Extends::Float
end
