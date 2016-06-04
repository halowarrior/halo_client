module Halo
  class Message < GameSpy::Messsage
    attr_accessor :header, :type, :sn, :esn, :data
    @@seq = -1

    def self.reset
      @@seq = -1
    end

    def initialize(input = nil, opts = {})
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
        fail "Invalid input type (#{input.class}): #{inspect}"
      end
    end

    def parse(buffer)
      if buffer.start_with?(GTI2_MAGIC_STRING)
        @header = buffer[0..6]
        @type = buffer[2].unpack('C').first
        @sn = buffer[3..4].unpack('S>').first
        @esn = buffer[5..6].unpack('S>').first
      end

      if is_encrypted?
        @data = decrypt(buffer[7..-1])
      else
        @data = buffer[7..-1]
      end
    end

    def as_bytes
      m = build_header
      if @data
        if encrypt?
          m += encrypt(@data)
        else
          m += @data
        end
      end
      m
    end

    def explain
      type_text = @header.start_with?(GTI2_MAGIC_STRING) ? 'Reliable' : 'Unreliable'
      complete_message = as_bytes

      %(
        Message Type: #{type_text}
        Type: #{@type}
        SN: #{@sn}
        ESN: #{@esn}
        Data: #{@data.unpack('H*').first}
        Data Len: #{@data.length}

        Complete Message: #{complete_message.unpack('H*').first}
        Complete Len: #{complete_message.length}
      )
    end

    private

    def build_header
      header = GTI2_MAGIC_STRING.force_encoding('ASCII-8BIT')
      header += [@type].pack('C')
      header += [@sn].pack('S>')
      header += [@esn].pack('S>')
      fail 'ERROR: header wrong len' unless header.length == 7
      header
    end

    def is_encrypted?
      @sn >= 2 && @esn >= 2
    end

    def encrypt?
      @sn >= 2 && @esn >= 3
    end
  end
end
