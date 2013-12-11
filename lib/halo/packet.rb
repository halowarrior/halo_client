module Halo
  class Packet
    attr_accessor :message, :function, :number, :unknown_number, :header
    @@seq = -1

    def self.reset
      @@seq = -1
    end

    def initialize( input = nil, opts = {} )
      @opts = opts    
      case input.class.to_s.downcase
      when 'string'
        parse(input)
      when 'hash'
        @function = input.delete(:function) || 0
        @seq      = input.delete(:seq)
        @ack      = input.delete(:ack) || 0
        @message  = input.delete(:message)
        input.each{ |key, val| self.instance_variable_set(:"@#{key}", val) }
      else
        raise "Invalid input type (#{input.class.to_s}): #{self.inspect}"
      end
    end

    def parse( buffer )
      @header   =  buffer[0..6] # 7 bytes
      @function =  buffer[2].unpack('c').first
      @number   =  buffer[4].unpack('S>').first
      if @opts[:cryptor]
        message = buffer[7..-5]
        packet_crc = buffer[-4..-1].unpack('L') # 4 byte crc32
        raise "CRC checksum failed (#{crc32(message)},#{packet_crc}) on Packet\##{self.object_id}" if crc32(message) != packet_crc
        @message = @opts[:cryptor].send(:decrypt, message)
      else
        @message = buffer[7..-1]
      end
    end

    def as_bytestream
      raise "Error: Cannot build a new packet with an incoming packet instance #{self.inspect}" if @direction == :incoming
      seq = @seq ? [@seq].pack('S>') : [@@seq + 1].pack('S>')
      ack = @ack ? [@ack].pack('S>') : [0].pack('S>')

      packet = "\xfe\xfe".force_encoding("ASCII-8BIT")
      packet += [@function].pack('c')
      packet += seq
      packet += ack
      if @opts[:cryptor]
        packet += @opts[:cryptor].send(:encrypt, @message)
        packet += crc32(packet[7..-1]).pack('I')
      else
        packet += @message if @message
      end
      packet
    end

    def send
      raise "Error: send() method was not set!" unless @opts[:send_proc]
      @opts[:send_proc].call( as_bytestream )
      @@seq +=1
    end
  end
end