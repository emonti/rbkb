
module Enumerable
  def each_recursive(&block)
    self.each do |n|
      block.call(n)
      n.each_recursive(&block) if Enumerable === n
    end
  end
end
