
class Array

  # Should be in the std library.
  #
  #   keys = [:one, :two, :three]
  #   vals = [1, 2, 3]
  #
  #   keys.zip(vals).to_hash
  #   #=> {:two=>2, :three=>3, :one=>1}})
  #
  #   keys.to_hash(vals)
  #   #=> {:two=>2, :three=>3, :one=>1}})
  def to_hash(vals=nil)
    a = vals ? self.zip(vals) : self
    a.inject({}) {|hash, i| hash[i[0]] = i[1]; hash}
  end

  # randomizes the order of contents in the Array (self)
  def randomize
    self.sort_by{ rand }
  end

  # Returns a randomly chosen element from self.
  def rand_elem
    self[rand(self.count)]
  end
end

