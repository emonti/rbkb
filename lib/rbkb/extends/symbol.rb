class Symbol
  # looks up this symbol as a constant defined in 'ns' (Object by default)
  def const_lookup(ns = Object)
    to_s.const_lookup(ns)
  end
end
