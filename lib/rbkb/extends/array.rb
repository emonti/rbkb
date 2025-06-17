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
  def to_hash(vals = nil)
    a = vals ? zip(vals) : self
    a.each_with_object({}) do |i, hash|
      hash[i[0]] = i[1]
    end
  end

  # randomizes the order of contents in the Array (self)
  def randomize
    sort_by { rand }
  end

  # Returns a randomly chosen element from self.
  def rand_elem
    self[rand(count)]
  end
end
