module Enumerable
  def each_recursive(&block)
    each do |n|
      block.call(n)
      n.each_recursive(&block) if n.is_a?(Enumerable)
    end
  end

  def sum
    inject(0) { |accum, i| accum + i }
  end

  def mean
    sum / length.to_f
  end

  def sample_variance
    m = mean
    sum = inject(0) { |accum, i| accum + (i - m)**2 }
    sum / (length - 1).to_f
  end

  def standard_deviation
    Math.sqrt(sample_variance)
  end
end

