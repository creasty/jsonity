require 'jsonity/attribute'

class Object

  extend Jsonity::Attribute::ClassMethods
  include Jsonity::Attribute::InstanceMethods

end
