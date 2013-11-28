module Halo
  class Client
    extend FFI::Library
    ffi_lib File.expand_path('../../halo_tea.bundle', __FILE__)
    
    VERSION = 616

    CHALLENGE_HEADERS = [ "\xFE\xFE\x01\x00\x00\x00\x00", 
                          "\xFE\xFE\x02\x00\x00\x00\x01",
                          "\xFE\xFE\x03\x00\x01\x00\x01",
                        ]

    def initialize(host, port, opts = {})
      @hash = FFI::MemoryPointer.new(:int32, 17)
      @encryption_key = FFI::MemoryPointer.new(:int32, 17)
      @decryption_key = FFI::MemoryPointer.new(:int32, 17)
      @buffer = []
      @host = host
      @port = port
      @opts = opts
      @state = :connecting
      @socket = UDPSocket.new(Socket::AF_INET)
      @packet_number = 0
    end

    def connect
      @socket.connect(@host, @port)
      @state = :connected
      run while @state != :finished 
    end

    def run
      read
      case @state
      when :connected
        packet = Packet.create({function: 1, number: @packet_number, message: GameSpy.challenge }) #CHALLENGE_HEADERS[0] + GameSpy.challenge
        send(packet.build)
        @packet_number += 1
        @state = :process_challenge
      when :process_challenge
        if server_packet = @buffer.shift
          server_packet = Packet.from_buffer(server_packet)
          client_packet = Packet.create({function: 3, number: @packet_number, unknown_number: "\x01" })
          Tea.generate_key(@hash, nil, @encryption_key)
          client_packet.message = GameSpy.challenge(server_packet.message[32..-1]) + 
                                  Tea.generate_key(@hash, nil, @encryption_key) + 
                                  encode_version(VERSION)


          raise_parse_error(client_packet.message) unless client_packet.message.length + 7 == 59
          send(client_packet.build)
          @packet_number += 1
          @state = :generate_keys
        end
      when :generate_keys
        if server_packet = @buffer.shift
          server_packet = Packet.from_buffer(server_packet)
          # debugger
          # raise_parse_error(server_packet.message) unless server_packet.message.length == 64
          Tea.generate_key(@hash, server_packet.message, @encryption_key)
          Tea.generate_key(@hash, server_packet.message, @decryption_key)
          @state = :start_encrypted_communication
        end
      when :start_encrypted_communication
        if server_packet = @buffer.shift 
          debugger
          @tea = Tea.new(@encryption_key, @decryption_key, @hash)
          server_packet = Packet.from_buffer(server_packet, { opts: { cryptor: @tea }})
          puts 1
        end
      end

    end

    private
      
      def encode_version( version )
        [ version * 1000 ].pack('L')
      end

      def raise_parse_error(data)
        raise "Error: Could not parse packet #{data} for state #{@state}"
      end

      def read( length = 20000 )
        bytes = @socket.recvfrom_nonblock(length) rescue ['']
        @buffer << bytes.first if bytes.first.length > 0
      end

      def send data
        @socket.send( data, 0)
      end

      def remove_bytes_from_buffer( length )
        bytes = @buffer[0..length-1]
        @buffer = @buffer[length..-1]
        bytes
      end
  end
end