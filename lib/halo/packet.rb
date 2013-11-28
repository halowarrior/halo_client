class Packet
  extend FFI::Library
  ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)

  attach_function :halo_crc32, [:pointer, :int32], :int32

  attr_accessor :message, :function, :number, :unknown_number, :header # might need this for debugging

  def self.from_buffer( buffer, args = {} )
    Packet.new(buffer, :incoming, args)
  end

  def self.create( args = {})
    Packet.new(nil, :outgoing, args)
  end

  def initialize( buffer, direction, args = {} )
    @opts = args.delete(:opts) || {}
    @direction = direction
    if @direction == :incoming
      parse(buffer)
    elsif @direction == :outgoing
      @function = @opts.delete(:function) || 0
      @number   = @opts.delete(:number)   || 0 
      args.each{ |key, val| self.instance_variable_set(:"@#{key}", val) }
    else
      raise "Invalid packet state (#{direction.to_s}): #{self.inspect}"
    end
  end

  def parse( buffer )
    @header   =  buffer[0..6] # 7 bytes
    @function =  buffer[3].unpack('c').first
    @number   =  buffer[4].unpack('S>').first
    if @opts[:cryptor]
      message = buffer[7..-5]
      packet_crc = buffer[-4..-1].unpack('L') # 4 byte crc32

      debugger

      raise "CRC checksum failed (#{crc32(message)},#{packet_crc}) on Packet\##{self.object_id}" if crc32(message) != packet_crc
      @message = @opts[:cryptor].send(:decrypt, message)
    else
      @message = buffer[7..-1]
    end
  end

  def build
    raise "Error: Cannot build a new packet with an incoming packet instance #{self.inspect}" if @direction == :incoming
    packet = "\xfe\xfe"
    packet += [@function].pack('c')
    packet += [@number].pack('S>')
    packet += "\x00"
    packet += @unknown_number || "\x00"
    if @opts[:cryptor]
      packet += @opts[:cryptor].send(:encrypt, @message)
      packet += crc32(packet[7..-1]).pack('I')
    else
      packet += @message
    end
    packet
  end

  def to_s

  end

  private
    def crc32(data)
      m = FFI::MemoryPointer.new(:int32, data.length + 1)
      m.write_string(data)
      halo_crc32(m, data.length)
    end
end