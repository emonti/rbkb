
class Object
  ## This is from Topher Cyll's Stupd IRB tricks
  def mymethods
    (self.methods - self.class.superclass.methods).sort
  end
end
