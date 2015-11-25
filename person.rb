class Person
  attr_accessor :name, :group, :email, :santa, :exclude

  def initialize(attrs)
    self.name  = attrs["name"]
    self.group = attrs["group"]
    self.email = attrs["email"]
    self.exclude = attrs["exclude"]
  end

  def can_be_santa_of?(other)
    group_ = (group == other.group) 
    exclude_ = (exclude != other.name) 
    name_ = (name != other.name)

    return (name_ && exclude_ && group_)
  end

  def can_swap_santas_with?(other)
    santa.can_be_santa_of?(other) && other.santa.can_be_santa_of?(self)
  end

  def to_s
    "#{name} (#{group})"
  end

  def with_santa
    "#{self} - santa: #{santa}"
  end

end
