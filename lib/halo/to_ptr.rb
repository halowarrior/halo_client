require 'ffi'

class String
  def to_ptr(type = :uint8, order = nil)
    ptr = FFI::MemoryPointer.new(type, self.length + 1)
    ptr.order(order.to_sym) if order
    ptr.write_string( self )
    ptr
  end
end

# numeric arrays
class Array
  def to_ptr
    ptr = FFI::MemoryPointer.new(:uint8, self.length)
    ptr.put_array_of_uint8(0, self)
    ptr
  end
end

class NilClass
  def to_ptr
    nil
  end
end