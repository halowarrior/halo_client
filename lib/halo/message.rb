module Halo
  class Message < GameSpy::Messsage
    attr_accessor :header, :type, :sn, :esn, :data
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
        @type   =   input.delete(:type) || 0
        @sn     =   input.delete(:sn) || 0
        @esn    =   input.delete(:esn) || 0
        @data   =   input.delete(:data)

        @header =   build_header
      else
        raise "Invalid input type (#{input.class.to_s}): #{self.inspect}"
      end
    end

    def parse( buffer )
      if buffer.start_with?(GTI2_MAGIC_STRING)
        @header = buffer[0..6] # 7 bytes
        @type = buffer[2].unpack("C").first
        @sn = buffer[3..4].unpack("S>").first
        @esn = buffer[5..6].unpack("S>").first
      end

      if @opts[:cryptor]
        data = buffer[7..-5]
        packet_crc = buffer[-4..-1].unpack('L') # 4 byte crc32
        raise "CRC checksum failed (#{crc32(data)},#{packet_crc}) on Packet\##{self.object_id}" if crc32(data) != packet_crc
        @data = @opts[:cryptor].send(:decrypt, data)
      else
        @data = buffer[7..-1]
      end
    end

    def as_bytes
      raise "Error: Cannot build a new packet with an incoming packet instance #{self.inspect}" if @direction == :incoming
      m = build_header
      m += @data if @data
      m
    end

    def explain
      type_text = @header.start_with?(GTI2_MAGIC_STRING) ? "Reliable" : "Unreliable"
      complete_message = as_bytes

      %(
        Message Type: #{type_text}
        Type: #{@type}
        SN: #{@sn}
        ESN: #{@esn}
        Data: #{@data.unpack("H*").first}
        Data Len: #{@data.length}

        Complete Message: #{complete_message.unpack("H*").first}
        Complete Len: #{complete_message.length}
      )
    end

    private

    def build_header
      header = GTI2_MAGIC_STRING.force_encoding("ASCII-8BIT")
      header += [@type].pack('C')
      header += [@sn].pack('S>')
      header += [@esn].pack('S>')
      raise "ERROR: header wrong len" unless header.length == 7
      header
    end

  end
end