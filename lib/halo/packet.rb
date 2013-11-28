require 'ffi'

class Packet
  extend FFI::Library
  ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)

  attach_function :halo_crc32, [:pointer, :int], :char

  attr_writer :function, :number
  attr_accessor :message # might need this for debugging

  def self.from_buffer( buffer, args = {} )
    Packet.new(buffer, :incoming, args)
  end

  def self.create( args = {})
    Packet.new(nil, :outgoing, args)
  end

  def initialize( buffer, direction, args = {} )
    @opts = args.delete[:opts] || {}
    @direction = direction
    if @direction is :incoming
      parse buffer
    elsif @direction is :outgoing
      @function = @opts.delete :function || 0
      @number = @opts.delete :number || 0 
      args.each{ |key, val| self.send("#@{key}=", val) }
    else
      raise "Invalid packet state (#{direction.to_s}) on #{self.inspect}"
    end
  end

  def parse( buffer )
    @header   =  buffer[0..6] # 7 bytes
    @function =  buffer[3].unpack('c').first
    @number   =  buffer[4].unpack('S>').first
    if @opts[:cryptor]
      message = buffer[7..-5]
      packet_crc = buffer[-4..-1].unpack('L') # 4 byte crc32
      raise "CRC checksum failed (#{crc32(message)},#{packet_crc}) on #{self.inspect}" if crc32(message) != packet_crc
      @message = @opts[:cryptor].send(:decrypt, message)
    else
      @message = buffer[7..-1]
    end
    @message = message
  end

  def build
    raise "Error: Cannot build a new packet with an incoming packet instance #{self.inspect}" if @direction is :incoming
    packet = "\xfe\xfe"
    packet += [@function].pack('c')
    packet += [@number].pack('S>')
    packet += opts[:cryptor] ? opts[:cryptor].send(:encrypt, @message) : @message
    packet += crc32(packet[7..-1])
    packet
  end

  def to_s
    build
  end

  private
    def crc32(data)
      m = FFI::MemoryPointer.new(:char, data.length + 1)
      m.write_string(data)
      halo_crc32(m, data.length)
    end
end